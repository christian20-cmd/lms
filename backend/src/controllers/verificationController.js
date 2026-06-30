const prisma = require('../config/database')
const { validerFormatEmail, validerTelephone, validerMotDePasse, validerNom } = require('../utils/validation')

const verifierEmail = async (req, res) => {
  try {
    const { emailUser } = req.body

    const formatValide = validerFormatEmail(emailUser)
    if (!formatValide.valide) {
      return res.status(400).json({ disponible: false, message: formatValide.message })
    }

    const userExiste = await prisma.user.findUnique({
      where: { emailUser }
    })

    if (userExiste) {
      return res.status(400).json({ disponible: false, message: 'Cet email est déjà utilisé' })
    }

    res.status(200).json({ disponible: true, message: 'Email disponible' })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const verifierTelephone = async (req, res) => {
  try {
    const { numeroTelUser, idPays } = req.body

    if (!idPays) {
      return res.status(400).json({ valide: false, message: 'Veuillez sélectionner un pays d\'abord' })
    }

    const operateurs = await prisma.operateur.findMany({
      where: { idPays }
    })

    const validation = validerTelephone(numeroTelUser, operateurs)

    if (!validation.valide) {
      return res.status(400).json({ valide: false, message: validation.message })
    }

    const telExiste = await prisma.user.findFirst({
      where: { numeroTelUser }
    })

    if (telExiste) {
      return res.status(400).json({ valide: false, message: 'Ce numéro est déjà utilisé' })
    }

    res.status(200).json({
      valide: true,
      message: 'Numéro valide',
      operateur: validation.operateur
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const verifierMotDePasse = (req, res) => {
  const { passwordUser } = req.body
  const validation = validerMotDePasse(passwordUser)
  if (!validation.valide) {
    return res.status(400).json({ valide: false, message: validation.message })
  }
  res.status(200).json({ valide: true, message: 'Mot de passe valide' })
}

const verifierNom = (req, res) => {
  const { nom } = req.body
  const validation = validerNom(nom)
  if (!validation.valide) {
    return res.status(400).json({ valide: false, message: validation.message })
  }
  res.status(200).json({ valide: true, message: 'Nom valide' })
}

module.exports = { verifierEmail, verifierTelephone, verifierMotDePasse, verifierNom }
