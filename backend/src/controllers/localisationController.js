const prisma = require('../config/database')

const getPays = async (req, res) => {
  try {
    const pays = await prisma.pays.findMany({
      orderBy: { nomPays: 'asc' }
    })
    res.status(200).json(pays)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const getVillesByPays = async (req, res) => {
  try {
    const { idPays } = req.params
    const villes = await prisma.ville.findMany({
      where: { idPays },
      orderBy: { nomVille: 'asc' }
    })
    res.status(200).json(villes)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const getOperateursByPays = async (req, res) => {
  try {
    const { idPays } = req.params
    const operateurs = await prisma.operateur.findMany({
      where: { idPays }
    })
    res.status(200).json(operateurs)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const getEtablissementsByVille = async (req, res) => {
  try {
    const { idVille } = req.params
    const etablissements = await prisma.etablissement.findMany({
      where: { idVille },
      orderBy: { nomEtablissement: 'asc' }
    })
    res.status(200).json(etablissements)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { getPays, getVillesByPays, getOperateursByPays, getEtablissementsByVille }