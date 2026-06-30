const express = require('express')
const router = express.Router({ mergeParams: true })
const { proteger } = require('../middlewares/authMiddleware')
const { autoriser } = require('../middlewares/roleMiddleware')
const { uploadVideo, uploadImage,uploadDocument } = require('../middlewares/uploadMiddleware')
const { ajouterContenu, getContenus, modifierContenu, supprimerContenu } = require('../controllers/contenuController')

const uploadDynamique = (req, res, next) => {
  const type = req.query.typeContenu

  if (type === 'VIDEO') {
    uploadVideo.single('fichier')(req, res, next)
  } else if (type === 'DOCUMENT') {
    uploadDocument.single('fichier')(req, res, next)
  } else if (type === 'IMAGE') {
    uploadImage.single('fichier')(req, res, next)
  } else {
    next()
  }
}

router.get('/', proteger, getContenus)
router.post('/', proteger, autoriser('ENSEIGNANT'), uploadDynamique, ajouterContenu)
router.put('/:idContenu', proteger, autoriser('ENSEIGNANT'), uploadDynamique, modifierContenu)
router.delete('/:idContenu', proteger, autoriser('ENSEIGNANT'), supprimerContenu)

module.exports = router