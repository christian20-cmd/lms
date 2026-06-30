const express = require('express')
const cors = require('cors')
require('dotenv').config()

const app = express()

const passport = require('./config/passport')
const localisationRoutes = require('./routes/localisationRoutes')
const authRoutes = require('./routes/authRoutes')
const oauthRoutes = require('./routes/oauthRoutes')
const coursRoutes = require('./routes/coursRoutes')
const moduleRoutes = require('./routes/moduleRoutes')
const contenuRoutes = require('./routes/contenuRoutes')
const inscriptionRoutes = require('./routes/inscriptionRoutes')
const notificationRoutes = require('./routes/notificationRoutes')
const profilRoutes = require('./routes/profilRoutes')
const dashboardRoutes = require('./routes/dashboardRoutes')

app.use(cors())
app.use(express.json())
app.use(express.urlencoded({ extended: true }))
app.use(passport.initialize())

// Fichiers statiques
app.use('/uploads', express.static('uploads'))

// Test route
app.get('/', (req, res) => {
  res.json({ message: 'LMS API fonctionne !' })
})

// Routes — imbriquées avant parentes
app.use('/api/cours/:idCours/modules/:idModule/contenus', contenuRoutes)
app.use('/api/cours/:idCours/modules', moduleRoutes)
app.use('/api/cours', coursRoutes)
app.use('/api/auth', oauthRoutes)
app.use('/api/auth', authRoutes)
app.use('/api', localisationRoutes)
app.use('/api', inscriptionRoutes)
app.use('/api/notifications', notificationRoutes)
app.use('/api/profil', profilRoutes)
app.use('/api/dashboard', dashboardRoutes)


module.exports = app