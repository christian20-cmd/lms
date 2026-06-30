const express = require('express')
const router = express.Router({ mergeParams: true })
const { proteger } = require('../middlewares/authMiddleware')
const { autoriser } = require('../middlewares/roleMiddleware')
const {
  creerModule,
  getModules,
  modifierModule,
  toggleStatutModule,
  supprimerModule
} = require('../controllers/moduleController')

router.get('/', proteger, getModules)
router.post('/', proteger, autoriser('ENSEIGNANT'), creerModule)
router.put('/:idModule', proteger, autoriser('ENSEIGNANT'), modifierModule)
router.patch('/:idModule/toggle-statut', proteger, autoriser('ENSEIGNANT'), toggleStatutModule)
router.delete('/:idModule', proteger, autoriser('ENSEIGNANT'), supprimerModule)

module.exports = router