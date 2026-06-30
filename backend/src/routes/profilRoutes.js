const express = require('express')
const router = express.Router()
const { proteger } = require('../middlewares/authMiddleware')
const { autoriser } = require('../middlewares/roleMiddleware')
const { uploadImage } = require('../middlewares/uploadMiddleware')
const {
  getMonProfil,
  modifierProfil,
  uploadPhoto,
  modifierMotDePasse,
  modifierProfilEnseignant,
  ajouterReseauSocial,
  modifierReseauSocial,
  supprimerReseauSocial,
  modifierProfilApprenant
} = require('../controllers/profilController')

// Commun
router.get('/', proteger, getMonProfil)
router.put('/', proteger, modifierProfil)
router.post('/photo', proteger, uploadImage.single('photo'), uploadPhoto)
router.put('/mot-de-passe', proteger, modifierMotDePasse)

// Enseignant
router.put('/enseignant', proteger, autoriser('ENSEIGNANT'), modifierProfilEnseignant)
router.post('/enseignant/reseaux-sociaux', proteger, autoriser('ENSEIGNANT'), ajouterReseauSocial)
router.put('/enseignant/reseaux-sociaux/:idReseauxSociaux', proteger, autoriser('ENSEIGNANT'), modifierReseauSocial)
router.delete('/enseignant/reseaux-sociaux/:idReseauxSociaux', proteger, autoriser('ENSEIGNANT'), supprimerReseauSocial)

// Apprenant
router.put('/apprenant', proteger, autoriser('APPRENANT'), modifierProfilApprenant)

module.exports = router