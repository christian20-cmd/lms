const express = require('express')
const router = express.Router()
const { proteger } = require('../middlewares/authMiddleware')
const { autoriser } = require('../middlewares/roleMiddleware')
const { getDashboard } = require('../controllers/dashboardController')
const { getDashboardApprenant } = require('../controllers/dashboardApprenantController')

router.get('/enseignant', proteger, autoriser('ENSEIGNANT'), getDashboard)
router.get('/apprenant/statistiques', proteger, autoriser('APPRENANT'), getDashboardApprenant)

module.exports = router