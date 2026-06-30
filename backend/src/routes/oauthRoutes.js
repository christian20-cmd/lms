const express = require('express')
const router = express.Router()
const passport = require('../config/passport')
const { googleCallback, githubCallback, completerProfil } = require('../controllers/oauthController')
const { proteger } = require('../middlewares/authMiddleware')

// Google
router.get('/google',
  passport.authenticate('google', { scope: ['profile', 'email'], session: false })
)
router.get('/google/callback',
  passport.authenticate('google', { session: false, failureRedirect: '/api/auth/oauth/error' }),
  googleCallback
)

// GitHub
router.get('/github',
  passport.authenticate('github', { scope: ['user:email'], session: false })
)
router.get('/github/callback',
  passport.authenticate('github', { session: false, failureRedirect: '/api/auth/oauth/error' }),
  githubCallback
)

// Compléter profil après OAuth
router.post('/completer-profil', proteger, completerProfil)

// Erreur
router.get('/error', (req, res) => {
  res.redirect(`${process.env.FRONTEND_URL}/oauth?error=true`)
})

module.exports = router