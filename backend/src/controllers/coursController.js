const prisma = require('../config/database')

// Vérifier titre dynamiquement
const verifierTitre = async (req, res) => {
  try {
    const { titreCours } = req.body

    if (!titreCours) {
      return res.status(400).json({ valide: false, message: 'Titre obligatoire' })
    }

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) {
      return res.status(403).json({ message: 'Enseignant introuvable' })
    }

    const titreExiste = await prisma.cours.findFirst({
      where: {
        titreCours: { equals: titreCours, mode: 'insensitive' },
        idEnseignant: enseignant.idEnseignant
      }
    })

    if (titreExiste) {
      return res.status(400).json({ valide: false, message: 'Vous avez déjà un cours avec ce titre' })
    }

    res.status(200).json({ valide: true, message: 'Titre disponible' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Créer un cours
const creerCours = async (req, res) => {
  try {
    const {
      titreCours, descriptionCours, prixCours,
      estGratuitCours, niveauCours, idCategorie,
      tagsExistants, nouveauxTags
    } = req.body

    // Champs obligatoires
    if (!titreCours || !descriptionCours || !niveauCours || !idCategorie) {
      return res.status(400).json({ message: 'Titre, description, niveau et catégorie sont obligatoires' })
    }

    if (!estGratuitCours && !prixCours) {
      return res.status(400).json({ message: 'Prix obligatoire pour un cours payant' })
    }

    // Récupérer enseignant
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    // Vérifier titre unique
    const titreExiste = await prisma.cours.findFirst({
      where: {
        titreCours: { equals: titreCours, mode: 'insensitive' },
        idEnseignant: enseignant.idEnseignant
      }
    })

    if (titreExiste) {
      return res.status(400).json({ message: 'Vous avez déjà un cours avec ce titre' })
    }

    // Vérifier catégorie
    const categorie = await prisma.categorie.findUnique({
      where: { idCategorie }
    })

    if (!categorie) {
      return res.status(400).json({ message: 'Catégorie introuvable' })
    }

    // Transaction
    const cours = await prisma.$transaction(async (tx) => {
      // Créer le cours
      const nouveauCours = await tx.cours.create({
        data: {
          titreCours,
          descriptionCours,
          prixCours: estGratuitCours ? null : parseFloat(prixCours),
          estGratuitCours: estGratuitCours === true || estGratuitCours === 'true',
          niveauCours,
          statutCours: 'BROUILLON',
          idEnseignant: enseignant.idEnseignant,
          idCategorie,
          imageCouvertureCours: req.file ? `/uploads/images/${req.file.filename}` : null
        }
      })

      // Gérer les tags existants
      if (tagsExistants && tagsExistants.length > 0) {
        await tx.coursTag.createMany({
          data: tagsExistants.map(idTag => ({
            idCours: nouveauCours.idCours,
            idTag
          }))
        })
      }

      // Créer et associer les nouveaux tags
      if (nouveauxTags && nouveauxTags.length > 0) {
        for (const nomTag of nouveauxTags) {
          let tag = await tx.tag.findUnique({
            where: { nomTag: nomTag.trim() }
          })

          if (!tag) {
            tag = await tx.tag.create({
              data: { nomTag: nomTag.trim() }
            })
          }

          await tx.coursTag.create({
            data: { idCours: nouveauCours.idCours, idTag: tag.idTag }
          })
        }
      }

      return nouveauCours
    })

    // Retourner le cours avec ses relations
    const coursComplet = await prisma.cours.findUnique({
      where: { idCours: cours.idCours },
      include: {
        categorie: true,
        tags: { include: { tag: true } },
        enseignant: { include: { user: { select: { nomUser: true, prenomUser: true } } } }
      }
    })

    res.status(201).json({ message: 'Cours créé avec succès', cours: coursComplet })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Lister tous les cours publiés avec filtres
const getCours = async (req, res) => {
  try {
    const { search, niveau, idCategorie, gratuit, idTag, page = 1, limite = 10 } = req.query

    const where = { statutCours: 'PUBLIE' }

    if (search) {
      where.OR = [
        { titreCours: { contains: search, mode: 'insensitive' } },
        { descriptionCours: { contains: search, mode: 'insensitive' } }
      ]
    }

    if (niveau) where.niveauCours = niveau
    if (idCategorie) where.idCategorie = idCategorie
    if (gratuit !== undefined) where.estGratuitCours = gratuit === 'true'
    if (idTag) where.tags = { some: { idTag } }

    const total = await prisma.cours.count({ where })
    const totalPages = Math.ceil(total / parseInt(limite))

    const cours = await prisma.cours.findMany({
      where,
      include: {
        categorie: true,
        tags: { include: { tag: true } },
        enseignant: { include: { user: { select: { nomUser: true, prenomUser: true, photoProfilUser: true } } } },
        _count: { select: { modules: true, inscriptions: true } }
      },
      orderBy: { dateCreationCours: 'desc' },
      skip: (parseInt(page) - 1) * parseInt(limite),
      take: parseInt(limite)
    })

    res.status(200).json({ cours, total, totalPages, page: parseInt(page) })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Détail d'un cours
const getCoursById = async (req, res) => {
  try {
    const { idCours } = req.params

    const cours = await prisma.cours.findUnique({
      where: { idCours },
      include: {
        categorie: true,
        tags: { include: { tag: true } },
        enseignant: {
          include: {
            user: { select: { nomUser: true, prenomUser: true, photoProfilUser: true, bioUser: true } },
            reseauxSociaux: true
          }
        },
        modules: {
          orderBy: { ordreModule: 'asc' },
          include: { _count: { select: { contenus: true } } }
        },
        _count: { select: { inscriptions: true } }
      }
    })

    if (!cours) {
      return res.status(404).json({ message: 'Cours introuvable' })
    }

    res.status(200).json(cours)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Mes cours (enseignant)
const getMesCours = async (req, res) => {
  try {
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    const cours = await prisma.cours.findMany({
      where: { idEnseignant: enseignant.idEnseignant },
      include: {
        categorie: true,
        tags: { include: { tag: true } },
        _count: { select: { modules: true, inscriptions: true } }
      },
      orderBy: { dateCreationCours: 'desc' }
    })

    res.status(200).json(cours)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier un cours
const modifierCours = async (req, res) => {
  try {
    const { idCours } = req.params
    const {
      titreCours, descriptionCours, prixCours,
      estGratuitCours, niveauCours, idCategorie,
      tagsExistants, nouveauxTags
    } = req.body

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    const cours = await prisma.cours.findUnique({ where: { idCours } })

    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Vous ne pouvez pas modifier ce cours' })
    }

    const coursModifie = await prisma.$transaction(async (tx) => {
      const updated = await tx.cours.update({
        where: { idCours },
        data: {
          titreCours: titreCours || cours.titreCours,
          descriptionCours: descriptionCours || cours.descriptionCours,
          prixCours: estGratuitCours ? null : parseFloat(prixCours) || cours.prixCours,
          estGratuitCours: estGratuitCours !== undefined ? estGratuitCours : cours.estGratuitCours,
          niveauCours: niveauCours || cours.niveauCours,
          idCategorie: idCategorie || cours.idCategorie,
          imageCouvertureCours: req.file ? `/uploads/images/${req.file.filename}` : cours.imageCouvertureCours
        }
      })

      // Mettre à jour les tags
      if (tagsExistants || nouveauxTags) {
        await tx.coursTag.deleteMany({ where: { idCours } })

        if (tagsExistants && tagsExistants.length > 0) {
          await tx.coursTag.createMany({
            data: tagsExistants.map(idTag => ({ idCours, idTag }))
          })
        }

        if (nouveauxTags && nouveauxTags.length > 0) {
          for (const nomTag of nouveauxTags) {
            let tag = await tx.tag.findUnique({ where: { nomTag: nomTag.trim() } })
            if (!tag) {
              tag = await tx.tag.create({ data: { nomTag: nomTag.trim() } })
            }
            await tx.coursTag.create({ data: { idCours, idTag: tag.idTag } })
          }
        }
      }

      return updated
    })

    res.status(200).json({ message: 'Cours modifié avec succès', cours: coursModifie })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Toggle statut publié/brouillon
const toggleStatutCours = async (req, res) => {
  try {
    const { idCours } = req.params

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })

    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Vous ne pouvez pas modifier ce cours' })
    }

    const nouveauStatut = cours.statutCours === 'PUBLIE' ? 'BROUILLON' : 'PUBLIE'

    const coursModifie = await prisma.cours.update({
      where: { idCours },
      data: { statutCours: nouveauStatut }
    })

    res.status(200).json({
      message: `Cours ${nouveauStatut === 'PUBLIE' ? 'publié' : 'dépublié'} avec succès`,
      statutCours: nouveauStatut
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Supprimer un cours
const supprimerCours = async (req, res) => {
  try {
    const { idCours } = req.params

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })

    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Vous ne pouvez pas supprimer ce cours' })
    }

    await prisma.cours.delete({ where: { idCours } })

    res.status(200).json({ message: 'Cours supprimé avec succès' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = {
  verifierTitre,
  creerCours,
  getCours,
  getCoursById,
  getMesCours,
  modifierCours,
  toggleStatutCours,
  supprimerCours
}