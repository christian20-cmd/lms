const prisma = require('../config/database')

const sInscrire = async (req, res) => {
  try {
    const { idCours } = req.params
    const apprenant = await prisma.apprenant.findUnique({ where: { idUser: req.user.idUser } })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })
    if (cours.statutCours !== 'PUBLIE') return res.status(400).json({ message: 'Ce cours n\'est pas disponible' })

    const dejaInscrit = await prisma.inscription.findFirst({ where: { idApprenant: apprenant.idApprenant, idCours } })
    if (dejaInscrit) return res.status(400).json({ message: 'Vous êtes déjà inscrit à ce cours' })

    const inscription = await prisma.inscription.create({
      data: { idApprenant: apprenant.idApprenant, idCours, statutPaiement: cours.estGratuitCours ? 'GRATUIT' : 'EN_ATTENTE' }
    })
    // Notifier l'enseignant
    const enseignant = await prisma.enseignant.findUnique({
    where: { idEnseignant: cours.idEnseignant }
    })

    if (enseignant) {
    await prisma.notification.create({
        data: {
        idEnseignant: enseignant.idEnseignant,
        idCours,
        messageNotification: `${req.user.prenomUser} ${req.user.nomUser} s'est inscrit à votre cours "${cours.titreCours}"`
        }
    })
    }
    res.status(201).json({ message: 'Inscription réussie', inscription })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const seDesinscrire = async (req, res) => {
  try {
    const { idCours } = req.params
    const apprenant = await prisma.apprenant.findUnique({ where: { idUser: req.user.idUser } })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const inscription = await prisma.inscription.findFirst({ where: { idApprenant: apprenant.idApprenant, idCours } })
    if (!inscription) return res.status(404).json({ message: 'Inscription introuvable' })

    const modules = await prisma.module.findMany({ where: { idCours } })
    const idModules = modules.map(m => m.idModule)

    await prisma.progression.deleteMany({ where: { idApprenant: apprenant.idApprenant, idModule: { in: idModules } } })
    await prisma.inscription.delete({ where: { idInscription: inscription.idInscription } })

    res.status(200).json({ message: 'Désinscription réussie' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const verifierInscription = async (req, res) => {
  try {
    const { idCours } = req.params
    const apprenant = await prisma.apprenant.findUnique({ where: { idUser: req.user.idUser } })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const inscription = await prisma.inscription.findFirst({ where: { idApprenant: apprenant.idApprenant, idCours } })
    res.status(200).json({ estInscrit: !!inscription, inscription: inscription || null })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const getMesCoursList = async (req, res) => {
  try {
    const apprenant = await prisma.apprenant.findUnique({ where: { idUser: req.user.idUser } })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const inscriptions = await prisma.inscription.findMany({
      where: { idApprenant: apprenant.idApprenant },
      include: {
        cours: {
          include: {
            categorie: true,
            enseignant: { include: { user: { select: { nomUser: true, prenomUser: true, photoProfilUser: true } } } },
            _count: { select: { modules: true } }
          }
        }
      },
      orderBy: { dateInscription: 'desc' }
    })

    res.status(200).json(inscriptions)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const getStatsCours = async (req, res) => {
  try {
    const { idCours } = req.params
    const enseignant = await prisma.enseignant.findUnique({ where: { idUser: req.user.idUser } })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const cours = await prisma.cours.findUnique({ where: { idCours } })
    if (!cours) return res.status(404).json({ message: 'Cours introuvable' })
    if (cours.idEnseignant !== enseignant.idEnseignant) return res.status(403).json({ message: 'Accès refusé' })

    const totalInscrits = await prisma.inscription.count({ where: { idCours } })
    const totalCompletes = await prisma.inscription.count({ where: { idCours, dateCompletionCours: { not: null } } })
    const tauxCompletion = totalInscrits > 0 ? Math.round((totalCompletes / totalInscrits) * 100) : 0

    res.status(200).json({ totalInscrits, totalCompletes, tauxCompletion })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { sInscrire, seDesinscrire, verifierInscription, getMesCoursList, getStatsCours }