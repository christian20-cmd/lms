const passport = require('passport')
const GoogleStrategy = require('passport-google-oauth20').Strategy
const GitHubStrategy = require('passport-github2').Strategy
const prisma = require('./database')

passport.use(new GoogleStrategy({
  clientID: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  callbackURL: '/api/auth/google/callback'
}, async (accessToken, refreshToken, profile, done) => {
  try {
    const emailUser = profile.emails?.[0]?.value
    if (!emailUser) return done(null, false)

    let user = await prisma.user.findUnique({ where: { emailUser } })

    if (user) {
      return done(null, { user, isNewUser: false })
    }

    // Créer compte partiel
    const result = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          nomUser: profile.name?.familyName || profile.displayName || 'User',
          prenomUser: profile.name?.givenName || '',
          emailUser,
          passwordUser: '',
          roleUser: 'APPRENANT', // rôle par défaut, sera modifié
          photoProfilUser: profile.photos?.[0]?.value || null,
        }
      })
      return newUser
    })

    return done(null, { user: result, isNewUser: true })
  } catch (error) {
    return done(error, false)
  }
}))

passport.use(new GitHubStrategy({
  clientID: process.env.GITHUB_CLIENT_ID,
  clientSecret: process.env.GITHUB_CLIENT_SECRET,
  callbackURL: '/api/auth/github/callback',
  scope: ['user:email']
}, async (accessToken, refreshToken, profile, done) => {
  try {
    const emailUser = profile.emails?.[0]?.value
    if (!emailUser) return done(null, false)

    let user = await prisma.user.findUnique({ where: { emailUser } })

    if (user) {
      return done(null, { user, isNewUser: false })
    }

    const displayName = profile.displayName || profile.username || 'User'
    const parts = displayName.split(' ')

    const result = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          nomUser: parts[0] || displayName,
          prenomUser: parts[1] || '',
          emailUser,
          passwordUser: '',
          roleUser: 'APPRENANT',
          photoProfilUser: profile.photos?.[0]?.value || null,
        }
      })
      return newUser
    })

    return done(null, { user: result, isNewUser: true })
  } catch (error) {
    return done(error, false)
  }
}))

module.exports = passport