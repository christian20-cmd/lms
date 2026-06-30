const prisma = require('../config/database')
const getMesNotifications = async (req, res) => {
  try {
    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const notifications = await prisma.notification.findMany({
      where: { idApprenant: apprenant.idApprenant },
      include: {
        cours: { select: { idCours: true, titreCours: true, imageCouvertureCours: true } }
      },
      orderBy: { dateEnvoiNotification: 'desc' }
    })

    res.status(200).json(notifications)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}
// Récupérer mes notifications
// Notifications enseignant
const getMesNotificationsEnseignant = async (req, res) => {
  try {
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const notifications = await prisma.notification.findMany({
      where: { idEnseignant: enseignant.idEnseignant },
      include: {
        cours: { select: { idCours: true, titreCours: true, imageCouvertureCours: true } }
      },
      orderBy: { dateEnvoiNotification: 'desc' }
    })

    res.status(200).json(notifications)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const compterNonLuesEnseignant = async (req, res) => {
  try {
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    const count = await prisma.notification.count({
      where: { idEnseignant: enseignant.idEnseignant, estLuNotification: false }
    })

    res.status(200).json({ nonLues: count })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const marquerToutesCommeLuesEnseignant = async (req, res) => {
  try {
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    await prisma.notification.updateMany({
      where: { idEnseignant: enseignant.idEnseignant, estLuNotification: false },
      data: { estLuNotification: true }
    })

    res.status(200).json({ message: 'Toutes les notifications marquées comme lues' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Compter les notifications non lues
const compterNonLues = async (req, res) => {
  try {
    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const count = await prisma.notification.count({
      where: { idApprenant: apprenant.idApprenant, estLuNotification: false }
    })

    res.status(200).json({ nonLues: count })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Marquer une notification comme lue
const marquerCommeLue = async (req, res) => {
  try {
    const { idNotification } = req.params

    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const notification = await prisma.notification.findUnique({
      where: { idNotification }
    })
    if (!notification) return res.status(404).json({ message: 'Notification introuvable' })

    if (notification.idApprenant !== apprenant.idApprenant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    await prisma.notification.update({
      where: { idNotification },
      data: { estLuNotification: true }
    })

    res.status(200).json({ message: 'Notification marquée comme lue' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Marquer toutes comme lues
const marquerToutesCommeLues = async (req, res) => {
  try {
    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    await prisma.notification.updateMany({
      where: { idApprenant: apprenant.idApprenant, estLuNotification: false },
      data: { estLuNotification: true }
    })

    res.status(200).json({ message: 'Toutes les notifications marquées comme lues' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Supprimer une notification manuellement
const supprimerNotification = async (req, res) => {
  try {
    const { idNotification } = req.params

    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    const notification = await prisma.notification.findUnique({
      where: { idNotification }
    })
    if (!notification) return res.status(404).json({ message: 'Notification introuvable' })

    if (notification.idApprenant !== apprenant.idApprenant) {
      return res.status(403).json({ message: 'Accès refusé' })
    }

    await prisma.notification.delete({ where: { idNotification } })

    res.status(200).json({ message: 'Notification supprimée' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

// Suppression automatique — notifications lues depuis plus de 30 jours
const supprimerAnciennesNotifications = async () => {
  try {
    const il_y_a_30_jours = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)

    const result = await prisma.notification.deleteMany({
      where: {
        estLuNotification: true,
        dateEnvoiNotification: { lt: il_y_a_30_jours }
      }
    })

    console.log(`✓ ${result.count} anciennes notifications supprimées`)
  } catch (error) {
    console.error('Erreur suppression automatique notifications:', error.message)
  }
}

module.exports = {
  getMesNotifications,
  compterNonLues,
  marquerCommeLue,
  marquerToutesCommeLues,
  supprimerNotification,
  supprimerAnciennesNotifications,
  getMesNotificationsEnseignant,
  compterNonLuesEnseignant,
  marquerToutesCommeLuesEnseignant
}