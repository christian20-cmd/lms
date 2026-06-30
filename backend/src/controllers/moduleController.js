const prisma = require('../config/database')

// Créer un module
const creerModule = async (req, res) => {
  try {
    const { idCours } = req.params
    const { titreModule, descriptionModule, ordreModule } = req.body

    if (!titreModule || !descriptionModule) {
      return res.status(400).json({ message: 'Titre et description obligatoires' })
    }

    // Vérifier que le cours appartient à l'enseignant
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })

    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Vous ne pouvez pas modifier ce cours' })
    }

    // Calculer l'ordre automatiquement si non fourni
    let ordre = ordreModule
    if (!ordre) {
      const dernierModule = await prisma.module.findFirst({
        where: { idCours },
        orderBy: { ordreModule: 'desc' }
      })
      ordre = dernierModule ? dernierModule.ordreModule + 1 : 1
    }

    const module = await prisma.module.create({
      data: {
        titreModule,
        descriptionModule,
        ordreModule: ordre,
        idCours
      }
    })

    res.status(201).json({ message: 'Module créé avec succès', module })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Lister les modules d'un cours
const getModules = async (req, res) => {
  try {
    const { idCours } = req.params

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    const modules = await prisma.module.findMany({
      where: { idCours },
      orderBy: { ordreModule: 'asc' },
      include: {
        _count: { select: { contenus: true } }
      }
    })

    res.status(200).json(modules)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Modifier un module
const modifierModule = async (req, res) => {
  try {
    const { idCours, idModule } = req.params
    const { titreModule, descriptionModule, ordreModule } = req.body

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

    const moduleModifie = await prisma.module.update({
      where: { idModule },
      data: {
        titreModule: titreModule || module.titreModule,
        descriptionModule: descriptionModule || module.descriptionModule,
        ordreModule: ordreModule || module.ordreModule
      }
    })

    res.status(200).json({ message: 'Module modifié avec succès', module: moduleModifie })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Toggle statut
const toggleStatutModule = async (req, res) => {
  try {
    const { idCours, idModule } = req.params

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    const module = await prisma.module.findUnique({ where: { idModule } })
    if (!module) return res.status(404).json({ message: 'Module introuvable' })

    const nouveauStatut = module.statutModule === 'PUBLIE' ? 'BROUILLON' : 'PUBLIE'

    const moduleModifie = await prisma.module.update({
      where: { idModule },
      data: { statutModule: nouveauStatut }
    })

    // Si module publié → notifier tous les apprenants inscrits
    if (nouveauStatut === 'PUBLIE') {
      const inscriptions = await prisma.inscription.findMany({
        where: { idCours }
      })

      if (inscriptions.length > 0) {
        await prisma.notification.createMany({
          data: inscriptions.map(ins => ({
            idApprenant: ins.idApprenant,
            idCours,
            messageNotification: `Nouveau module disponible : ${moduleModifie.titreModule}`
          }))
        })
      }
    }

    res.status(200).json({
      message: `Module ${nouveauStatut === 'PUBLIE' ? 'publié' : 'dépublié'} avec succès`,
      statutModule: nouveauStatut
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}
// Supprimer un module
const supprimerModule = async (req, res) => {
  try {
    const { idCours, idModule } = req.params

    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })

    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })

    if (cours.idEnseignant !== enseignant.idEnseignant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    const module = await prisma.module.findUnique({ where: { idModule } })
    if (!module) return res.status(404).json({ message: 'Module introuvable' })

    await prisma.module.delete({ where: { idModule } })

    res.status(200).json({ message: 'Module supprimé avec succès' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = {
  creerModule,
  getModules,
  modifierModule,
  toggleStatutModule,
  supprimerModule
}