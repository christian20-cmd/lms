/*
  Warnings:

  - A unique constraint covering the columns `[idApprenant,idModule]` on the table `Progression` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "Progression_idApprenant_idModule_key" ON "Progression"("idApprenant", "idModule");
