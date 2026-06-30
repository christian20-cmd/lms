const jwt = require('jsonwebtoken')
const prisma = require('../config/database')

const proteger = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'Token manquant ou invalide' })
    }

    const token = authHeader.split(' ')[1]

    const decoded = jwt.verify(token, process.env.JWT_SECRET)

    const user = await prisma.user.findUnique({
      where: { idUser: decoded.idUser }
    })

    if (!user) {
      return res.status(401).json({ message: 'Utilisateur introuvable' })
    }

    req.user = user
    next()
  } catch (error) {
    res.status(401).json({ message: 'Token invalide ou expiré' })
  }
}

module.exports = { proteger }