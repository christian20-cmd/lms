const autoriser = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.roleUser)) {
      return res.status(403).json({ message: 'Accès refusé — permission insuffisante' })
    }
    next()
  }
}

module.exports = { autoriser }