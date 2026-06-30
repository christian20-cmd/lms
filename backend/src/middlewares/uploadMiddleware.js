const multer = require('multer')
const path = require('path')

const storage = (dossier) => multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, `uploads/${dossier}`)
  },
  filename: (req, file, cb) => {
    const unique = Date.now() + '-' + Math.round(Math.random() * 1e9)
    cb(null, unique + path.extname(file.originalname))
  }
})

const filtreImage = (req, file, cb) => {
  const types = /jpeg|jpg|png|webp/
  if (types.test(path.extname(file.originalname).toLowerCase())) {
    cb(null, true)
  } else {
    cb(new Error('Seules les images sont acceptées'))
  }
}

const uploadImage = multer({ storage: storage('images'), fileFilter: filtreImage })
const uploadVideo = multer({ storage: storage('videos') })
const uploadDocument = multer({ storage: storage('documents') })

module.exports = { uploadImage, uploadVideo, uploadDocument }