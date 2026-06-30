-- CreateTable
CREATE TABLE "CodeVerification" (
    "idCode" TEXT NOT NULL,
    "codeVerification" TEXT NOT NULL,
    "emailUser" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "estUtilise" BOOLEAN NOT NULL DEFAULT false,
    "dateCreation" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CodeVerification_pkey" PRIMARY KEY ("idCode")
);
