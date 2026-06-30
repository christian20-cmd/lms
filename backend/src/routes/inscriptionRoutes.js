const express = require('express')
const router = express.Router()
const { proteger } = require('../middlewares/authMiddleware')
const { autoriser } = require('../middlewares/roleMiddleware')
const { sInscrire, seDesinscrire, verifierInscription, getMesCoursList, getStatsCours } = require('../controllers/inscriptionController')
const { marquerTermine, getProgression, reinitialiserProgression, getCoursCompletes } = require('../controllers/progressionController')

// Inscription
router.post('/cours/:idCours/inscrire', proteger, autoriser('APPRENANT'), sInscrire)
router.delete('/cours/:idCours/desinscrire', proteger, autoriser('APPRENANT'), seDesinscrire)
router.get('/cours/:idCours/inscription', proteger, autoriser('APPRENANT'), verifierInscription)
router.get('/mes-inscriptions', proteger, autoriser('APPRENANT'), getMesCoursList)
router.get('/cours/:idCours/stats', proteger, autoriser('ENSEIGNANT'), getStatsCours)

// Progression
router.post('/cours/:idCours/modules/:idModule/terminer', proteger, autoriser('APPRENANT'), marquerTermine)
router.get('/cours/:idCours/progression', proteger, autoriser('APPRENANT'), getProgression)
router.delete('/cours/:idCours/progression/reinitialiser', proteger, autoriser('APPRENANT'), reinitialiserProgression)
router.get('/mes-cours-completes', proteger, autoriser('APPRENANT'), getCoursCompletes)

module.exports = router