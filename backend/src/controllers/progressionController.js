const prisma = require('../config/database')

// Marquer un module comme terminé
const marquerTermine = async (req, res) => {
  try {
    const { idCours, idModule } = req.params

    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    // Vérifier inscription
    const inscription = await prisma.inscription.findFirst({
      where: { idApprenant: apprenant.idApprenant, idCours }
    })
    if (!inscription) return res.status(403).json({ message: 'Vous n\'êtes pas inscrit à ce cours' })

    const module = await prisma.module.findUnique({ where: { idModule } })
    if (!module) return res.status(404).json({ message: 'Module introuvable' })

    // Créer ou mettre à jour la progression
    const progression = await prisma.progression.upsert({
      where: {
        idApprenant_idModule: {
          idApprenant: apprenant.idApprenant,
          idModule
        }
      },
      update: { estTermine: true, dateCompletion: new Date() },
      create: {
        idApprenant: apprenant.idApprenant,
        idModule,
        estTermine: true,
        dateCompletion: new Date()
      }
    })

    // Vérifier si tous les modules sont terminés
    const totalModules = await prisma.module.count({
      where: { idCours, statutModule: 'PUBLIE' }
    })

    const modulesTermines = await prisma.progression.count({
      where: { idApprenant: apprenant.idApprenant, idModule: { in: await prisma.module.findMany({ where: { idCours } }).then(m => m.map(x => x.idModule)) }, estTermine: true }
    })

    // Si tous terminés → mettre à jour dateCompletionCours
    if (modulesTermines >= totalModules && totalModules > 0) {
      await prisma.inscription.update({
        where: { idInscription: inscription.idInscription },
        data: { dateCompletionCours: new Date() }
      })
    }

    const pourcentage = totalModules > 0 ? Math.round((modulesTermines / totalModules) * 100) : 0

    res.status(200).json({
      message: 'Module marqué comme terminé',
      progression,
      pourcentage,
      coursComplete: modulesTermines >= totalModules
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Récupérer la progression d'un cours
const getProgression = async (req, res) => {
  try {
    const { idCours } = req.params

    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const inscription = await prisma.inscription.findFirst({
      where: { idApprenant: apprenant.idApprenant, idCours }
    })
    if (!inscription) return res.status(403).json({ message: 'Vous n\'êtes pas inscrit à ce cours' })

    const modules = await prisma.module.findMany({
      where: { idCours },
      orderBy: { ordreModule: 'asc' }
    })

    const progressions = await prisma.progression.findMany({
      where: {
        idApprenant: apprenant.idApprenant,
        idModule: { in: modules.map(m => m.idModule) }
      }
    })

    const modulesAvecProgression = modules.map(m => ({
      ...m,
      estTermine: progressions.find(p => p.idModule === m.idModule)?.estTermine || false,
      dateCompletion: progressions.find(p => p.idModule === m.idModule)?.dateCompletion || null
    }))

    const totalModules = modules.length
    const modulesTermines = progressions.filter(p => p.estTermine).length
    const pourcentage = totalModules > 0 ? Math.round((modulesTermines / totalModules) * 100) : 0

    res.status(200).json({
      pourcentage,
      modulesTermines,
      totalModules,
      coursComplete: inscription.dateCompletionCours !== null,
      dateCompletionCours: inscription.dateCompletionCours,
      modules: modulesAvecProgression
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Réinitialiser la progression
const reinitialiserProgression = async (req, res) => {
  try {
    const { idCours } = req.params

    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const inscription = await prisma.inscription.findFirst({
      where: { idApprenant: apprenant.idApprenant, idCours }
    })
    if (!inscription) return res.status(403).json({ message: 'Vous n\'êtes pas inscrit à ce cours' })

    const modules = await prisma.module.findMany({ where: { idCours } })
    const idModules = modules.map(m => m.idModule)

    await prisma.progression.deleteMany({
      where: { idApprenant: apprenant.idApprenant, idModule: { in: idModules } }
    })

    await prisma.inscription.update({
      where: { idInscription: inscription.idInscription },
      data: { dateCompletionCours: null }
    })

    res.status(200).json({ message: 'Progression réinitialisée' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Cours complétés par l'apprenant
const getCoursCompletes = async (req, res) => {
  try {
    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const coursCompletes = await prisma.inscription.findMany({
      where: {
        idApprenant: apprenant.idApprenant,
        dateCompletionCours: { not: null }
      },
      include: {
        cours: {
          include: {
            categorie: true,
            enseignant: {
              include: {
                user: { select: { nomUser: true, prenomUser: true } }
              }
            }
          }
        }
      }
    })

    res.status(200).json({ total: coursCompletes.length, cours: coursCompletes })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { marquerTermine, getProgression, reinitialiserProgression, getCoursCompletes }