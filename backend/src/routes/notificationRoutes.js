const express = require('express')
const router = express.Router()
const { proteger } = require('../middlewares/authMiddleware')
const { autoriser } = require('../middlewares/roleMiddleware')
const {
  getMesNotifications,
  compterNonLues,
  marquerCommeLue,
  marquerToutesCommeLues,
  supprimerNotification,
  getMesNotificationsEnseignant,
  compterNonLuesEnseignant,
  marquerToutesCommeLuesEnseignant
} = require('../controllers/notificationController')

// Apprenant
router.get('/', proteger, autoriser('APPRENANT'), getMesNotifications)
router.get('/non-lues', proteger, autoriser('APPRENANT'), compterNonLues)
router.patch('/toutes-lues', proteger, autoriser('APPRENANT'), marquerToutesCommeLues)
router.patch('/:idNotification/lue', proteger, autoriser('APPRENANT'), marquerCommeLue)
router.delete('/:idNotification', proteger, autoriser('APPRENANT'), supprimerNotification)

// Enseignant
router.get('/enseignant', proteger, autoriser('ENSEIGNANT'), getMesNotificationsEnseignant)
router.get('/enseignant/non-lues', proteger, autoriser('ENSEIGNANT'), compterNonLuesEnseignant)
router.patch('/enseignant/toutes-lues', proteger, autoriser('ENSEIGNANT'), marquerToutesCommeLuesEnseignant)

module.exports = router