const express = require('express')
const router = express.Router()
const { proteger } = require('../middlewares/authMiddleware')
const { autoriser } = require('../middlewares/roleMiddleware')
const { uploadImage } = require('../middlewares/uploadMiddleware')
const {
  verifierTitre, creerCours, getCours, getCoursById,
  getMesCours, modifierCours, toggleStatutCours, supprimerCours
} = require('../controllers/coursController')
const { creerCategorie, getCategories } = require('../controllers/categorieController')
const { getMesCoursList } = require('../controllers/inscriptionController')

// Catégories
router.get('/categories', proteger, getCategories)
router.post('/categories', proteger, autoriser('ENSEIGNANT'), creerCategorie)

// Cours — routes fixes AVANT la route générique /:idCours
router.get('/', proteger, getCours)
router.get('/mes-cours', proteger, autoriser('ENSEIGNANT'), getMesCours)
router.get('/mes-inscriptions', proteger, autoriser('APPRENANT'), getMesCoursList)
router.post('/verifier-titre', proteger, autoriser('ENSEIGNANT'), verifierTitre)
router.post('/', proteger, autoriser('ENSEIGNANT'), uploadImage.single('imageCouvertureCours'), creerCours)

// Route générique avec paramètre — TOUJOURS après les routes fixes
router.get('/:idCours', proteger, getCoursById)
router.put('/:idCours', proteger, autoriser('ENSEIGNANT'), uploadImage.single('imageCouvertureCours'), modifierCours)
router.patch('/:idCours/toggle-statut', proteger, autoriser('ENSEIGNANT'), toggleStatutCours)
router.delete('/:idCours', proteger, autoriser('ENSEIGNANT'), supprimerCours)

module.exports = router