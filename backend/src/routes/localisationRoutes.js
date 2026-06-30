const express = require('express')
const router = express.Router()
const { getPays, getVillesByPays, getOperateursByPays, getEtablissementsByVille } = require('../controllers/localisationController')
const { verifierEmail, verifierTelephone, verifierMotDePasse, verifierNom } = require('../controllers/verificationController')

router.post('/verifier-mot-de-passe', verifierMotDePasse)
router.post('/verifier-nom', verifierNom)
router.get('/pays', getPays)
router.get('/pays/:idPays/villes', getVillesByPays)
router.get('/pays/:idPays/operateurs', getOperateursByPays)
router.get('/villes/:idVille/etablissements', getEtablissementsByVille)
router.post('/verifier-email', verifierEmail)
router.post('/verifier-telephone', verifierTelephone)

module.exports = router