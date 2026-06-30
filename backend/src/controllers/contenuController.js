const prisma = require('../config/database')

// Ajouter un contenu
const ajouterContenu = async (req, res) => {
  try {
    const { idCours, idModule } = req.params
    const { titreContenu, typeContenu, ordreContenu, lienExterne, texteContenu } = req.body

    if (!titreContenu || !typeContenu) {
      return res.status(400).json({ message: 'Titre et type obligatoires' })
    }

    if (!['VIDEO', 'DOCUMENT', 'TEXTE', 'IMAGE'].includes(typeContenu)) {
      return res.status(400).json({ message: 'Type invalide. Valeurs acceptées : VIDEO, DOCUMENT, TEXTE, IMAGE' })
    }

    // Vérifier que l'enseignant possède le cours
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Vous ne pouvez pas modifier ce cours' })
    }

    const module = await prisma.module.findUnique({ where: { idModule } })
    if (!module) return res.status(404).json({ message: 'Module introuvable' })

    if (module.idCours !== idCours) {
      return res.status(400).json({ message: 'Ce module n\'appartient pas à ce cours' })
    }

    // Validation selon le type
    if (typeContenu === 'TEXTE' && !texteContenu) {
      return res.status(400).json({ message: 'Le contenu texte est obligatoire pour ce type' })
    }

    if (typeContenu === 'VIDEO' && !req.file && !lienExterne) {
      return res.status(400).json({ message: 'Un fichier vidéo ou un lien externe est obligatoire' })
    }

    if (typeContenu === 'DOCUMENT' && !req.file) {
      return res.status(400).json({ message: 'Un fichier document est obligatoire' })
    }

    // Calculer l'ordre automatiquement si non fourni
    let ordre = ordreContenu
    if (!ordre) {
      const dernierContenu = await prisma.contenu.findFirst({
        where: { idModule },
        orderBy: { ordreContenu: 'desc' }
      })
      ordre = dernierContenu ? dernierContenu.ordreContenu + 1 : 1
    }

    // Construire le chemin du fichier selon le type
    let fichierUrl = null
    if (req.file) {
      const dossier = typeContenu === 'VIDEO' ? 'videos' : typeContenu === 'IMAGE' ? 'images' : 'documents'
      fichierUrl = `/uploads/${dossier}/${req.file.filename}`
    }

    const contenu = await prisma.contenu.create({
      data: {
        titreContenu,
        typeContenu,
        ordreContenu: parseInt(ordre),
        fichierUrl,
        lienExterne: lienExterne || null,
        texteContenu: texteContenu || null,
        idModule
      }
    })

    res.status(201).json({ message: 'Contenu ajouté avec succès', contenu })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Lister les contenus d'un module
const getContenus = async (req, res) => {
  try {
    const { idModule } = req.params

    const module = await prisma.module.findUnique({ where: { idModule } })
    if (!module) return res.status(404).json({ message: 'Module introuvable' })

    const contenus = await prisma.contenu.findMany({
      where: { idModule },
      orderBy: { ordreContenu: 'asc' }
    })

    res.status(200).json(contenus)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier un contenu
const modifierContenu = async (req, res) => {
  try {
    const { idCours, idModule, idContenu } = req.params
    const { titreContenu, ordreContenu, lienExterne, texteContenu } = req.body

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Vous ne pouvez pas modifier ce cours' })
    }

    const contenu = await prisma.contenu.findUnique({ where: { idContenu } })
    if (!contenu) return res.status(404).json({ message: 'Contenu introuvable' })

    if (contenu.idModule !== idModule) {
      return res.status(400).json({ message: 'Ce contenu n\'appartient pas à ce module' })
    }

    // Nouveau fichier uploadé ?
    let fichierUrl = contenu.fichierUrl
    if (req.file) {
      const dossier = contenu.typeContenu === 'VIDEO' ? 'videos' : 'documents'
      fichierUrl = `/uploads/${dossier}/${req.file.filename}`
    }

    const contenuModifie = await prisma.contenu.update({
      where: { idContenu },
      data: {
        titreContenu: titreContenu || contenu.titreContenu,
        ordreContenu: ordreContenu ? parseInt(ordreContenu) : contenu.ordreContenu,
        lienExterne: lienExterne !== undefined ? lienExterne : contenu.lienExterne,
        texteContenu: texteContenu !== undefined ? texteContenu : contenu.texteContenu,
        fichierUrl
      }
    })

    res.status(200).json({ message: 'Contenu modifié avec succès', contenu: contenuModifie })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Supprimer un contenu
const supprimerContenu = async (req, res) => {
  try {
    const { idCours, idModule, idContenu } = req.params

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    const contenu = await prisma.contenu.findUnique({ where: { idContenu } })
    if (!contenu) return res.status(404).json({ message: 'Contenu introuvable' })

    if (contenu.idModule !== idModule) {
      return res.status(400).json({ message: 'Ce contenu n\'appartient pas à ce module' })
    }

    await prisma.contenu.delete({ where: { idContenu } })

    res.status(200).json({ message: 'Contenu supprimé avec succès' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { ajouterContenu, getContenus, modifierContenu, supprimerContenu }