const carriersWithProducts = {
  lumico: {
    name: "Lumico",
    products: {
      sife: {
        name: "SIFE",
        minCoverageAmount: 5,
        maxCoverageAmount: 50,
        multiplier: 1000,
        increaseStep: 1
      },
      siterm: {
        name: "SI Term",
        minCoverageAmount: 25,
        maxCoverageAmount: 500,
        multiplier: 1000,
        increaseStep: 25
      },
      levelterm: {
        name: "Level Term",
        minCoverageAmount: 150,
        maxCoverageAmount: 1000,
        multiplier: 1000,
        increaseStep: 25
      },
      ad: {
        name: "Accidental Death (Health Product)",
        minCoverageAmount: 100,
        maxCoverageAmount: 250,
        multiplier: 1000,
        increaseStep: 25
      },
      wl: {
        name: "Whole life",
        minCoverageAmount: 30,
        maxCoverageAmount: 1000,
        multiplier: 1000,
        increaseStep: 25
      }
    }
  },
  aig: {
    name: "AIG",
    products: {
      giwl: {
        name: "GIWL",
        minCoverageAmount: 5,
        maxCoverageAmount: 25,
        multiplier: 1000,
        increaseStep: 1
      }
    }
  },
  gerber: {
    name: "Gerber",
    products: {
      gife: {
        name: "GIFE",
        minCoverageAmount: 5,
        maxCoverageAmount: 25,
        multiplier: 1000,
        increaseStep: 1
      }
    }
  },
  aetna: {
    name: "Aetna",
    products: {
      "aetna-sife": {
        name: "SIFE",
        minCoverageAmount: 2,
        maxCoverageAmount: 50,
        multiplier: 1000,
        increaseStep: 1
      }
    }
  },
  reliashield: {
    name: "Reliashield",
    products: {
      "essential-individual": {
        name: "Essential - Individual",
        minCoverageAmount: 25,
        maxCoverageAmount: 25,
        multiplier: 1,
        increaseStep: 1
      },
      "essential-family": {
        name: "Essential - Family",
        minCoverageAmount: 25,
        maxCoverageAmount: 25,
        multiplier: 1,
        increaseStep: 1
      },
      "prime-individual": {
        name: "Prime - Individual",
        minCoverageAmount: 25,
        maxCoverageAmount: 25,
        multiplier: 1,
        increaseStep: 1
      },
      "prime-family": {
        name: "Prime - Family",
        minCoverageAmount: 25,
        maxCoverageAmount: 25,
        multiplier: 1,
        increaseStep: 1
      },
      "elite-individual": {
        name: "Elite - Individual",
        minCoverageAmount: 25,
        maxCoverageAmount: 25,
        multiplier: 1,
        increaseStep: 1
      },
      "elite-family": {
        name: "Elite - Family",
        minCoverageAmount: 25,
        maxCoverageAmount: 25,
        multiplier: 1,
        increaseStep: 1
      }
    }
  }
};

const levelTermCoverage = {
  "$150K - $200K": { options: [150000, 175000, 200000], minAge: 18, maxAge: 64 },
  "$250K - $500K": { options: [250000, 400000, 500000], minAge: 18, maxAge: 64 },
  "$600K - $750K": { options: [600000, 700000, 750000], minAge: 18, maxAge: 64 },
  "$800K - $1M": { options: [800000, 900000, 1000000], minAge: 18, maxAge: 64 },

  "$150K - $250K": { options: [150000, 175000, 200000, 250000], minAge: 65, maxAge: 70 }
};

const wholeLifeCoverage = {
  "$30K - $100K": { options: [30000, 50000, 100000], minAge: 18, maxAge: 70 },
  "$125K - $250K": { options: [125000, 200000, 250000], minAge: 18, maxAge: 70 },
  "$250K - $500K": { options: [250000, 400000, 500000], minAge: 18, maxAge: 65 },
  "$600K - $750K": { options: [600000, 700000, 750000], minAge: 18, maxAge: 65 },
  "$800K - $1M": { options: [800000, 900000, 1000000], minAge: 18, maxAge: 65 }
};

const sifeRiskClassFaceAmounts = {
  Preferred: {
    options: [
      { minFaceAmount: 5000, maxFaceAmount: 20000, minAge: 76, maxAge: 80 },
      { minFaceAmount: 5000, maxFaceAmount: 30000, minAge: 71, maxAge: 75 },
      { minFaceAmount: 5000, maxFaceAmount: 40000, minAge: 61, maxAge: 70 },
      { minFaceAmount: 5000, maxFaceAmount: 50000, minAge: 40, maxAge: 60 }
    ]
  },
  Standard: { options: [{ minFaceAmount: 5000, maxFaceAmount: 30000, minAge: 50, maxAge: 85 }] },
  Modified: { options: [{ minFaceAmount: 5000, maxFaceAmount: 15000, minAge: 50, maxAge: 85 }] }
};

const heightValues = [
  { value: "54", label: "4' 6\"" },
  { value: "55", label: "4' 7\"" },
  { value: "56", label: "4' 8\"" },
  { value: "57", label: "4' 9\"" },
  { value: "58", label: "4' 10\"" },
  { value: "59", label: "4' 11\"" },
  { value: "60", label: "5' 0\"" },
  { value: "61", label: "5' 1\"" },
  { value: "62", label: "5' 2\"" },
  { value: "63", label: "5' 3\"" },
  { value: "64", label: "5' 4\"" },
  { value: "65", label: "5' 5\"" },
  { value: "66", label: "5' 6\"" },
  { value: "67", label: "5' 7\"" },
  { value: "68", label: "5' 8\"" },
  { value: "69", label: "5' 9\"" },
  { value: "70", label: "5' 10\"" },
  { value: "71", label: "5' 11\"" },
  { value: "72", label: "6' 0\"" },
  { value: "73", label: "6' 1\"" },
  { value: "74", label: "6' 2\"" },
  { value: "75", label: "6' 3\"" },
  { value: "76", label: "6' 4\"" },
  { value: "77", label: "6' 5\"" },
  { value: "78", label: "6' 6\"" },
  { value: "79", label: "6' 7\"" },
  { value: "80", label: "6' 8\"" },
  { value: "81", label: "6' 9\"" },
  { value: "82", label: "6' 10\"" },
  { value: "83", label: "6' 11\"" },
  { value: "84", label: "7' 0\"" },
  { value: "85", label: "7' 1\"" },
  { value: "86", label: "7' 2\"" },
  { value: "87", label: "7' 3\"" },
  { value: "88", label: "7' 4\"" },
  { value: "89", label: "7' 5\"" },
  { value: "90", label: "7' 6\"" }
];

const genders = { male: "Male", female: "Female" };

const statesShortForm = [
  "AL",
  "AK",
  "AZ",
  "AR",
  "CA",
  "CO",
  "CT",
  "DE",
  "DC",
  "FL",
  "GA",
  "HI",
  "ID",
  "IL",
  "IN",
  "IA",
  "KS",
  "KY",
  "LA",
  "ME",
  "MD",
  "MA",
  "MI",
  "MN",
  "MS",
  "MO",
  "MT",
  "NE",
  "NV",
  "NH",
  "NJ",
  "NM",
  "NY",
  "NC",
  "ND",
  "OH",
  "OK",
  "OR",
  "PA",
  "RI",
  "SC",
  "SD",
  "TN",
  "TX",
  "UT",
  "VT",
  "VA",
  "WA",
  "WV",
  "WI",
  "WY"
];

export {
  levelTermCoverage,
  heightValues,
  statesShortForm,
  genders,
  carriersWithProducts,
  wholeLifeCoverage,
  sifeRiskClassFaceAmounts
};