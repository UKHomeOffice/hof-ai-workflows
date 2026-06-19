# Modern Slavery NRM Parity Checklist

Purpose: force deterministic, one-pass migration completion for NRM by tracking source StepLib/page-object behavior groups against target Playwright implementation.

Source of truth:
- hof-e2e-auto-tests/Function/src/main/java/uk/gov/ho/domain/component/ui/stepLib/NrmStepLib.java
- hof-e2e-auto-tests/Function/src/main/java/domain/component/ui/pages/nrm/*

## Completed parity groups
- report setup: reference, organisation, report location
- age and local authority: under-18, under-18 during exploitation, local authority details
- background and exploitation timing: background, one/multiple exploitative situation, exploitation period, exploitation start
- movement and treatment: taken somewhere, treatment, still in exploitation or how they left
- reporting context: first time reporting, why reporting now
- referral quality evidence: indicators, interviews, professional insight, credibility concerns, other professionals
- exploitation location: UK, overseas, UK and overseas
- contact history: last contact and contact details

## Remaining parity groups to implement before PASS
1. answerWhereAreTheyHowWereTheyExploitedAndOtherPotentialVictims
- where is the potential victim staying
- who exploited the potential victim
- do you have information about exploiter whereabouts
- are exploiters in the UK
- what info about exploiter whereabouts
- how were they exploited
- were there other potential victims
- concerns about future exploitation
- why concerns about future exploitation (conditional)

2. answerDoTheyHaveCrimeRefNumbAndCooperationWithPubAuth
- crime reference number (conditional details)
- cooperation with public authorities (conditional details)

3. answerDoTheyWantTheirCaseReferredToNRMAndCompleteQuestionnaire
- consent to refer decision tree for adult and child pathways
- do they need support
- support provider contact route
- why do not refer path

4. answerQuestionsOnPotentialVictims and related identity/contact details
- name of potential victim
- date of birth
- gender
- children (conditional count)
- nationality
- interpreter (conditional language)
- communication support
- home office reference
- how should they be contacted
- check-your-answers data visibility branching

5. answerUploadEvidenceAndSupportingDocuments
- upload evidence yes/no path
- uploaded document details path

## Completion rules
- Execute remaining groups in list order unless source feature order requires a strict alternate sequence.
- Recompute parity counts after each implemented group.
- Continue within the same run until no unmapped groups remain or a hard blocker is proven.
- If blocked, include source method names, target files attempted, and exact blocker evidence.
