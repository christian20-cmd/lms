const prisma = require('../config/database')

const getDashboardApprenant = async (req, res) => {
  try {
    const apprenant = await prisma.apprenant.findUnique({
      where: { idUser: req.user.idUser }
    })
    if (!apprenant) return res.status(403).json({ message: 'Accès refusé' })

    // Toutes les inscriptions de l'apprenant, avec le cours et ses modules
    const inscriptions = await prisma.inscription.findMany({
      where: { idApprenant: apprenant.idApprenant },
      include: {
        cours: {
          include: {
            categorie: true,
            enseignant: {
              include: { user: { select: { nomUser: true, prenomUser: true, photoProfilUser: true } } }
            },
            modules: { select: { idModule: true, statutModule: true } },
            _count: { select: { modules: true } }
          }
        }
      },
      orderBy: { dateInscription: 'desc' }
    })

    const totalCours = inscriptions.length
    const coursTermines = inscriptions.filter(i => i.dateCompletionCours !== null).length

    // Progression par cours — modules terminés / total modules publiés
    const idModulesParCours = inscriptions.map(i => ({
      idCours: i.idCours,
      idsModules: i.cours.modules.filter(m => m.statutModule === 'PUBLIE').map(m => m.idModule)
    }))

    const tousLesIdsModules = idModulesParCours.flatMap(c => c.idsModules)

    const progressions = tousLesIdsModules.length > 0
      ? await prisma.progression.findMany({
          where: {
            idApprenant: apprenant.idApprenant,
            idModule: { in: tousLesIdsModules },
            estTermine: true
          }
        })
      : []

    const idsModulesTerminesSet = new Set(progressions.map(p => p.idModule))

    let sommeProgressionPourcentage = 0
    const coursAvecProgression = inscriptions.map(i => {
      const idsModules = i.cours.modules.filter(m => m.statutModule === 'PUBLIE').map(m => m.idModule)
      const totalModules = idsModules.length
      const modulesTermines = idsModules.filter(id => idsModulesTerminesSet.has(id)).length
      const pourcentage = totalModules > 0 ? Math.round((modulesTermines / totalModules) * 100) : 0
      sommeProgressionPourcentage += pourcentage

      return {
        idCours: i.idCours,
        titreCours: i.cours.titreCours,
        descriptionCours: i.cours.descriptionCours,
        imageCouvertureCours: i.cours.imageCouvertureCours,
        niveauCours: i.cours.niveauCours,
        categorie: i.cours.categorie,
        enseignant: {
          nom: i.cours.enseignant?.user?.nomUser,
          prenom: i.cours.enseignant?.user?.prenomUser,
          photoProfilUser: i.cours.enseignant?.user?.photoProfilUser
        },
        totalModules: i.cours._count.modules,
        progression: pourcentage,
        estTermine: i.dateCompletionCours !== null,
        dateInscription: i.dateInscription
      }
    })

    const progressionMoyenne = totalCours > 0 ? Math.round(sommeProgressionPourcentage / totalCours) : 0

    // Top 3 cours les plus avancés (en cours, pas terminés)
    const coursEnCours = coursAvecProgression
      .filter(c => !c.estTermine)
      .sort((a, b) => b.progression - a.progression)
      .slice(0, 3)

    res.status(200).json({
      statsGlobales: {
        totalCours,
        coursTermines,
        progressionMoyenne
      },
      cours: coursAvecProgression,
      coursEnCours
    })
  } catch (error) {
    res.status(500).json({ message: 'Erreur serveur', error: error.message })
  }
}

module.exports = { getDashboardApprenant }