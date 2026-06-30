const prisma = require('../config/database')

const creerCategorie = async (req, res) => {
  try {
    const { nomCategorie, iconeCategorie } = req.body

    if (!nomCategorie) {
      return res.status(400).json({ message: 'Nom de la catégorie obligatoire' })
    }

    const categorieExiste = await prisma.categorie.findFirst({
      where: { nomCategorie: { equals: nomCategorie, mode: 'insensitive' } }
    })

    if (categorieExiste) {
      return res.status(400).json({ message: 'Cette catégorie existe déjà' })
    }

    const categorie = await prisma.categorie.create({
      data: { nomCategorie, iconeCategorie: iconeCategorie || null }
    })

    res.status(201).json({ message: 'Catégorie créée avec succès', categorie })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

const getCategories = async (req, res) => {
  try {
    const categories = await prisma.categorie.findMany({
      orderBy: { nomCategorie: 'asc' }
    })
    res.status(200).json(categories)
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { creerCategorie, getCategories }