const express = require('express')
const router = express.Router()
const {
  validerNomPrenom,
  verifierEmailInscription,
  envoyerCodeVerification,
  verifierCode,
  validerPassword,
  register,
  login,
  verifierEmailLogin,
  demanderResetPassword,
  verifierCodeReset,
  reinitialiserPassword,
  validerToken
} = require('../controllers/authController')
const { proteger } = require('../middlewares/authMiddleware')

// Étapes inscription
router.post('/valider-nom-prenom', validerNomPrenom)
router.post('/verifier-email-inscription', verifierEmailInscription)
router.post('/envoyer-code', envoyerCodeVerification)
router.post('/verifier-code', verifierCode)
router.post('/valider-password', validerPassword)
router.post('/register', register)

// Login
router.post('/verifier-email-login', verifierEmailLogin)
router.post('/login', login)

router.post('/demander-reset-password', demanderResetPassword)
router.post('/verifier-code-reset', verifierCodeReset)
router.post('/reinitialiser-password', reinitialiserPassword)

// Validation du token (protégée)
router.get('/validate-token', proteger, validerToken)

module.exports = router
