const prisma = require('../config/database')

const getDashboard = async (req, res) => {
  try {
    const enseignant = await prisma.enseignant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!enseignant) return res.status(403).json({ message: 'Accès refusé' })

    // Tous les cours de l'enseignant
    const cours = await prisma.cours.findMany({
      where: { idEnseignant: enseignant.idEnseignant },
      include: {
        _count: { select: { modules: true, inscriptions: true } },
        inscriptions: true
      },
      orderBy: { dateCreationCours: 'desc' }
    })

    // Stats globales
    const totalCours = cours.length
    const totalPublies = cours.filter(c => c.statutCours === 'PUBLIE').length
    const totalBrouillons = cours.filter(c => c.statutCours === 'BROUILLON').length
    const totalInscrits = cours.reduce((acc, c) => acc + c._count.inscriptions, 0)

    // Taux de complétion moyen
    const completions = await prisma.inscription.findMany({
      where: {
        cours: { idEnseignant: enseignant.idEnseignant },
        dateCompletionCours: { not: null }
      }
    })
    const tauxCompletion = totalInscrits > 0
      ? Math.round((completions.length / totalInscrits) * 100)
      : 0

    // Données histogramme — inscrits par cours
    const donneesHistogramme = cours.map(c => ({
      idCours: c.idCours,
      titreCours: c.titreCours.length > 20
        ? c.titreCours.substring(0, 20) + '...'
        : c.titreCours,
      inscrits: c._count.inscriptions,
      modules: c._count.modules,
      statut: c.statutCours,
    }))

    // Top 3 cours populaires
    const topCours = [...donneesHistogramme]
      .sort((a, b) => b.inscrits - a.inscrits)
      .slice(0, 3)

    // Inscriptions par mois (6 derniers mois) pour courbe
    const sixMoisAvant = new Date()
    sixMoisAvant.setMonth(sixMoisAvant.getMonth() - 6)

    const inscriptionsParMois = await prisma.inscription.groupBy({
      by: ['dateInscription'],
      where: {
        cours: { idEnseignant: enseignant.idEnseignant },
        dateInscription: { gte: sixMoisAvant }
      },
      _count: { idInscription: true },
      orderBy: { dateInscription: 'asc' }
    })

    // Grouper par mois
    const moisMap = {}
    inscriptionsParMois.forEach(item => {
      const date = new Date(item.dateInscription)
      const key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`
      moisMap[key] = (moisMap[key] || 0) + item._count.idInscription
    })

    const courbeData = Object.entries(moisMap).map(([mois, count]) => ({
      mois,
      inscrits: count
    }))

    res.status(200).json({
      statsGlobales: {
        totalCours,
        totalPublies,
        totalBrouillons,
        totalInscrits,
        tauxCompletion
      },
      donneesHistogramme,
      topCours,
      courbeData
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { getDashboard }