# 194 — Home pad lines: one line, shorter text (no "…")

Status: ready-for-agent. Reported by Jakub on 2026-11-13 with an iPad screenshot (English).

## What Jakub saw

On Home in English, two pad lines are cut off with "…":
- 03 Continue: "Kick on every b…" (lesson "Kick on every beat").
- 05 Controller: "Network sessio…" (the iPad's network MIDI session, "Network session 1").

The Czech texts must be checked the same way ("Kick na každou dobu", "Síťová relace 1").

## Rules

1. **One line stays** (ticket 181). What changes: the text itself must be short enough to fit, so it never ends in "…". This replaces 181's "truncated to one line" for the Continue pad.
2. **Length limit: 14 characters** for any Home pad line, in both languages (fits the pad at the narrowest supported layout; confirm on the iPad A16 simulator in portrait and landscape and lower the limit if 14 does not fit).
3. **Controller:** for the network MIDI session show "Network MIDI" / "Síťový MIDI" instead of "Network session 1". Other device names longer than the limit are cut at a word boundary without "…" (or to the first word if one word is already too long).
4. **Continue:** show the lesson's **short name**. Add an optional short name per lesson as localized strings (key `home.short.<lesson title>` in both `Localizable.strings` files) for every lesson whose title is longer than the limit in either language; lessons that fit use their title. Short names must still say what the lesson is (e.g. "Kick on every beat" → "Kick on beats" / "Kick na doby"). Put the full list of new short names into this ticket under `## Short names` for Jakub to review.
5. Delete the old truncation code on the pad line; no dead code.

## Short names

| ID | Category | Original title | EN short name | CS short name |
|---:|:---|:---|:---|:---|
| 6 | starter | Open hat on the and | Open hat on & | Open hat na & |
| 26 | eighth | Rock halftime 1 | Rock half 1 | Rock half 1 |
| 134 | sixteenth | New Orleans funk 1 | NO funk 1 | NO funk 1 |
| 141 | sixteenth | Dance breakbeat | Dance break | Dance break |
| 148 | sixteenth | Jazz linear 1 | Jazz linear 1 | Lineár jazz 1 |
| 154 | sixteenth | Jazz linear 2 | Jazz linear 2 | Lineár jazz 2 |
| 159 | electronic | House: kick and clap | House: clap | House: clap |
| 160 | electronic | House: offbeat open hat | House open hat | House open hat |
| 161 | electronic | House: sixteenth hats | House 16th hat | House 16tiny |
| 162 | electronic | House: shaker groove | House: shaker | House: shaker |
| 166 | electronic | Disco with sixteenth hats | Disco 16th hat | Disco 16tiny |
| 167 | electronic | Techno: kick and open hat | Techno openhat | Techno openhat |
| 168 | electronic | Techno: offbeat rim | Techno rim & | Techno rim na& |
| 169 | electronic | Techno: rolling hats | Techno rolls | Techno valivá |
| 170 | electronic | Techno: syncopated rim | Techno syn-rim | Techno synkopy |
| 174 | electronic | Electro with pushed kick | Electro kick | Electro kick |
| 177 | electronic | Breakbeat, two bars | Breakbeat 2b | Break 2 takty |
| 178 | electronic | Two-step garage | 2-step garage | 2-step garage |
| 179 | electronic | Two-step garage with skip | 2-step skip | 2-step pauza |
| 180 | electronic | Two-step garage with shaker | 2-step shaker | 2-step shaker |
| 181 | electronic | Dubstep half-time | Dubstep half | Dubstep half |
| 182 | electronic | Dubstep with kick push | Dubstep kick | Dubstep kick |
| 183 | electronic | Dubstep with sixteenth hats | Dubstep 16ths | Dubstep 16tiny |
| 184 | electronic | Drum and bass two-step | DnB 2-step | DnB 2-step |
| 185 | electronic | Drum and bass, ghost snares | DnB ghost | DnB jemný |
| 186 | electronic | Drum and bass on the ride | DnB ride | DnB ride |
| 187 | electronic | Drum and bass, two bars | DnB 2 bars | DnB 2 takty |
| 188 | electronic | Jungle-style break | Jungle break | Jungle break |
| 190 | electronic | Boom bap with pushed kick | Boom bap kick | Boom bap kick |
| 191 | electronic | Boom bap with ghost snare | Boom bap ghost | Boom bap ghost |
| 195 | electronic | Trap with sixteenth hats | Trap 16th hats | Trap 16tiny |
| 196 | electronic | Trap with hat roll | Trap hat roll | Trap roll |
| 197 | electronic | Trap, two bars | Trap, two bars | Trap, 2 takty |
| 199 | electronic | Dembow with hats | Dembow hats | Dembow hi-hat |
| 200 | electronic | Dembow with rim and shaker | Dembow rim | Dembow rim |
| 202 | electronic | Moombahton with hats | Moombahton hat | Moombahton hat |
| 206 | ghost | Rock halftime 2 | Rock half 2 | Rock half 2 |
| 220 | ghost | Rock rockabilly 1 | Rockabilly 1 | Rockabilly 1 |
| 225 | ghost | New Orleans funk 2 | NO funk 2 | NO funk 2 |
| 230 | ghost | Jazz march 1 | Jazz march 1 | Jazz pochod 1 |
| 233 | ghost | Jazz march 2 | Jazz march 2 | Jazz pochod 2 |
| 235 | ghost | Jazz march 3 | Jazz march 3 | Jazz pochod 3 |
| 238 | ghost | Jazz march 4 | Jazz march 4 | Jazz pochod 4 |
| 246 | ghost | Jazz march 5 | Jazz march 5 | Jazz pochod 5 |
| 249 | ghost | New Orleans funk 3 | NO funk 3 | NO funk 3 |
| 251 | ghost | New Orleans funk 4 | NO funk 4 | NO funk 4 |
| 257 | ghost | New Orleans shuffle 1 | NO shuffle 1 | NO shuffle 1 |
| 259 | ghost | Jazz march 6 | Jazz march 6 | Jazz pochod 6 |
| 260 | ghost | New Orleans shuffle 2 | NO shuffle 2 | NO shuffle 2 |
| 261 | ghost | New Orleans funk 5 | NO funk 5 | NO funk 5 |
| 262 | ghost | New Orleans shuffle 3 | NO shuffle 3 | NO shuffle 3 |
| 263 | ghost | New Orleans funk 6 | NO funk 6 | NO funk 6 |
| 264 | ghost | New Orleans funk 7 | NO funk 7 | NO funk 7 |
| 265 | ghost | New Orleans shuffle 4 | NO shuffle 4 | NO shuffle 4 |
| 278 | swing | Funk purdieshuffle 1 | Purdie funk 1 | Purdie funk 1 |
| 286 | swing | Rock rockabilly 2 | Rockabilly 2 | Rockabilly 2 |
| 291 | swing | Funk purdieshuffle 2 | Purdie funk 2 | Purdie funk 2 |
| 303 | swing | Rock rockabilly 3 | Rockabilly 3 | Rockabilly 3 |
| 310 | swing | Rock rockabilly 4 | Rockabilly 4 | Rockabilly 4 |
| 311 | swing | Rock rockabilly 5 | Rockabilly 5 | Rockabilly 5 |
| 319 | swing | Jazz mediumfast | Jazz mid-fast | Střední jazz |
| 321 | swing | Rock shuffle 10 | Rock shuf 10 | Rock shuf 10 |
| 322 | swing | Rock rockabilly 6 | Rockabilly 6 | Rockabilly 6 |
| 325 | swing | Rock shuffle 11 | Rock shuf 11 | Rock shuf 11 |
| 326 | swing | Rock shuffle 12 | Rock shuf 12 | Rock shuf 12 |
| 327 | swing | Rock rockabilly 7 | Rockabilly 7 | Rockabilly 7 |
| 328 | world | Latin brazilian bossa 1 | Bossa 1 | Bossa 1 |
| 329 | world | Afro-Cuban rhumba 1 | Rhumba 1 | Rhumba 1 |
| 330 | world | Middle Eastern 1 | Mid East 1 | Východ 1 |
| 331 | world | Latin reggaeton | Reggaeton | Reggaeton |
| 332 | world | Afro-Cuban calypso 1 | Calypso 1 | Calypso 1 |
| 334 | world | Latin dominican merengue 1 | Merengue 1 | Merengue 1 |
| 342 | world | Afro-Cuban rhumba 2 | Rhumba 2 | Rhumba 2 |
| 346 | world | Latin brazilian maracatu 1 | Maracatu 1 | Maracatu 1 |
| 348 | world | Latin brazilian bossa 2 | Bossa 2 | Bossa 2 |
| 349 | world | Latin brazilian ijexa 1 | Ijexa 1 | Ijexa 1 |
| 350 | world | Latin brazilian | Brazil Latin | Brazil latina |
| 351 | world | Latin brazilian ijexa 2 | Ijexa 2 | Ijexa 2 |
| 352 | world | Latin brazilian baiao 1 | Baiao 1 | Baiao 1 |
| 358 | world | Middle Eastern 2 | Mid East 2 | Východ 2 |
| 361 | world | Latin brazilian baiao 2 | Baiao 2 | Baiao 2 |
| 363 | world | Afro-Cuban bembe | Bembe | Bembe |
| 364 | world | Latin brazilian samba 1 | Samba 1 | Samba 1 |
| 366 | world | Afro-Cuban calypso 2 | Calypso 2 | Calypso 2 |
| 368 | world | Middle Eastern 3 | Mid East 3 | Východ 3 |
| 371 | world | Afro-Cuban calypso 3 | Calypso 3 | Calypso 3 |
| 372 | world | Latin brazilian baiao 3 | Baiao 3 | Baiao 3 |
| 374 | world | Latin dominican merengue 2 | Merengue 2 | Merengue 2 |
| 375 | world | Latin dominican merengue 3 | Merengue 3 | Merengue 3 |
| 377 | world | Afro-Cuban calypso 4 | Calypso 4 | Calypso 4 |
| 378 | world | Latin brazilian sambareggae 1 | Samba reggae 1 | Samba reggae 1 |
| 380 | world | Afro-Cuban calypso 5 | Calypso 5 | Calypso 5 |
| 381 | world | Latin dominican merengue 4 | Merengue 4 | Merengue 4 |
| 382 | world | Brazilian sambareggae 2 | Samba reggae 2 | Samba reggae 2 |
| 383 | world | Afro-Cuban calypso 6 | Calypso 6 | Calypso 6 |
| 385 | world | Afro-Cuban calypso 7 | Calypso 7 | Calypso 7 |
| 387 | world | Brazilian sambareggae 3 | Samba reggae 3 | Samba reggae 3 |
| 389 | world | Afro-Cuban calypso 8 | Calypso 8 | Calypso 8 |
| 390 | world | Afro-Cuban calypso 9 | Calypso 9 | Calypso 9 |
| 393 | world | Afro-Cuban calypso 10 | Calypso 10 | Calypso 10 |
| 394 | world | Latin chacarera 1 | Chacarera 1 | Chacarera 1 |
| 395 | world | Latin chacarera 2 | Chacarera 2 | Chacarera 2 |
| 396 | world | Brazilian sambareggae 4 | Samba reggae 4 | Samba reggae 4 |
| 397 | world | Latin brazilian songo 1 | Songo 1 | Songo 1 |
| 398 | world | Afro-Cuban calypso 11 | Calypso 11 | Calypso 11 |
| 399 | world | Latin chacarera 3 | Chacarera 3 | Chacarera 3 |
| 402 | world | Latin chacarera 4 | Chacarera 4 | Chacarera 4 |
| 404 | world | Latin chacarera 5 | Chacarera 5 | Chacarera 5 |
| 405 | world | Latin dominican merengue 5 | Merengue 5 | Merengue 5 |
| 408 | world | Latin brazilian samba 2 | Samba 2 | Samba 2 |
| 409 | world | Latin chacarera 6 | Chacarera 6 | Chacarera 6 |
| 411 | world | Latin dominican merengue 6 | Merengue 6 | Merengue 6 |
| 415 | world | Latin chacarera 7 | Chacarera 7 | Chacarera 7 |
| 417 | world | Latin chacarera 8 | Chacarera 8 | Chacarera 8 |
| 418 | world | Latin brazilian ijexa 3 | Ijexa 3 | Ijexa 3 |
| 428 | world | Latin brazilian songo 2 | Songo 2 | Songo 2 |
| 431 | world | Latin brazilian songo 3 | Songo 3 | Songo 3 |
| 434 | world | Brazilian sambareggae 5 | Samba reggae 5 | Samba reggae 5 |
| 435 | world | Latin brazilian songo 4 | Songo 4 | Songo 4 |
| 436 | world | Brazilian sambareggae 6 | Samba reggae 6 | Samba reggae 6 |
| 438 | world | Latin brazilian frevo 1 | Frevo 1 | Frevo 1 |
| 439 | world | Latin brazilian samba 3 | Samba 3 | Samba 3 |
| 440 | world | Latin brazilian frevo 2 | Frevo 2 | Frevo 2 |
| 441 | world | Latin brazilian baiao 4 | Baiao 4 | Baiao 4 |
| 442 | world | Latin brazilian maracatu 2 | Maracatu 2 | Maracatu 2 |
| 443 | fills | Rock halftime fill 1 | Half fill 1 | Half fill 1 |
| 444 | fills | Country fill 1 | Country fill 1 | Country fill 1 |
| 445 | fills | Jazz fusion fill 1 | Fusion fill 1 | Fusion fill 1 |
| 446 | fills | Latin brazilian baiao fill 1 | Baiao fill 1 | Baiao fill 1 |
| 447 | fills | Latin samba fill 1 | Samba fill 1 | Samba fill 1 |
| 450 | fills | Funk rock fill 1 | Funk rock f. 1 | Funk rock f. 1 |
| 453 | fills | New Orleans funk fill 1 | NO funk f. 1 | NO funk f. 1 |
| 454 | fills | Funk rock fill 2 | Funk rock f. 2 | Funk rock f. 2 |
| 457 | fills | New Orleans funk fill 2 | NO funk f. 2 | NO funk f. 2 |
| 461 | fills | New Orleans funk fill 3 | NO funk f. 3 | NO funk f. 3 |
| 465 | fills | Country fill 2 | Country fill 2 | Country fill 2 |
| 467 | fills | Rock halftime fill 2 | Half fill 2 | Half fill 2 |
| 469 | fills | Funk purdieshuffle fill | Purdie fill | Purdie fill |
| 470 | fills | Gospel fill 1 | Gospel fill 1 | Gospel fill 1 |
| 471 | fills | Jazz fusion fill 2 | Fusion fill 2 | Fusion fill 2 |
| 473 | fills | Hip hop fill 1 | Hip hop fill 1 | Hip hop fill 1 |
| 474 | fills | Rock fill 10 | Rock fill 10 | Rock fill 10 |
| 475 | fills | Hip hop fill 2 | Hip hop fill 2 | Hip hop fill 2 |
| 476 | fills | Hip hop fill 3 | Hip hop fill 3 | Hip hop fill 3 |
| 477 | fills | New Orleans funk fill 4 | NO funk f. 4 | NO funk f. 4 |
| 478 | fills | Rock fill 11 | Rock fill 11 | Rock fill 11 |
| 479 | fills | Funk fast fill 1 | Fast funk f. 1 | Fast funk f. 1 |
| 481 | fills | Gospel fill 2 | Gospel fill 2 | Gospel fill 2 |
| 484 | fills | Hip hop fill 4 | Hip hop fill 4 | Hip hop fill 4 |
| 485 | fills | Jazz funk fill 1 | Jazz funk f. 1 | Jazz funk f. 1 |
| 486 | fills | Rock fill 12 | Rock fill 12 | Rock fill 12 |
| 487 | fills | Funk rock fill 3 | Funk rock f. 3 | Funk rock f. 3 |
| 488 | fills | New Orleans funk fill 5 | NO funk f. 5 | NO funk f. 5 |
| 489 | fills | New Orleans funk fill 6 | NO funk f. 6 | NO funk f. 6 |
| 491 | fills | Jazz funk fill 2 | Jazz funk f. 2 | Jazz funk f. 2 |
| 492 | fills | Hip hop fill 5 | Hip hop fill 5 | Hip hop fill 5 |
| 493 | fills | Funk fast fill 2 | Fast funk f. 2 | Fast funk f. 2 |
| 494 | fills | Funk rock fill 4 | Funk rock f. 4 | Funk rock f. 4 |
| 495 | fills | New Orleans funk fill 7 | NO funk f. 7 | NO funk f. 7 |
| 497 | fills | Jazz funk fill 3 | Jazz funk f. 3 | Jazz funk f. 3 |
| 498 | fills | Country fill 3 | Country fill 3 | Country fill 3 |
| 499 | fills | Rock fill 13 | Rock fill 13 | Rock fill 13 |
| 501 | fills | Jazz fusion fill 3 | Fusion fill 3 | Fusion fill 3 |
| 503 | fills | Funk fast fill 3 | Fast funk f. 3 | Fast funk f. 3 |
| 505 | fills | Rock fill 14 | Rock fill 14 | Rock fill 14 |
| 506 | fills | Hip hop fill 6 | Hip hop fill 6 | Hip hop fill 6 |
| 508 | fills | Rock fill 15 | Rock fill 15 | Rock fill 15 |
| 509 | fills | New Orleans funk fill 8 | NO funk f. 8 | NO funk f. 8 |
| 510 | fills | Rock fill 16 | Rock fill 16 | Rock fill 16 |
| 511 | fills | Rock fill 17 | Rock fill 17 | Rock fill 17 |
| 513 | fills | Soul motown fill | Motown fill | Motown fill |
| 514 | fills | Latin brazilian baiao fill 2 | Baiao fill 2 | Baiao fill 2 |
| 515 | fills | Hip hop fill 7 | Hip hop fill 7 | Hip hop fill 7 |
| 517 | fills | Rock halftime fill 3 | Half fill 3 | Half fill 3 |
| 518 | fills | Jazz funk fill 4 | Jazz funk f. 4 | Jazz funk f. 4 |
| 520 | fills | New Orleans funk fill 9 | NO funk f. 9 | NO funk f. 9 |
| 521 | fills | New Orleans funk fill 10 | NO funk f. 10 | NO funk f. 10 |
| 523 | fills | Rock halftime fill 4 | Half fill 4 | Half fill 4 |
| 524 | fills | New Orleans funk fill 11 | NO funk f. 11 | NO funk f. 11 |
| 525 | fills | Jazz funk fill 5 | Jazz funk f. 5 | Jazz funk f. 5 |
| 526 | fills | Jazz funk fill 6 | Jazz funk f. 6 | Jazz funk f. 6 |
| 527 | fills | Rock fill 18 | Rock fill 18 | Rock fill 18 |
| 528 | fills | Rock fill 19 | Rock fill 19 | Rock fill 19 |
| 529 | fills | New Orleans funk fill 12 | NO funk f. 12 | NO funk f. 12 |
| 530 | fills | Rock fill 20 | Rock fill 20 | Rock fill 20 |
| 531 | fills | New Orleans funk fill 13 | NO funk f. 13 | NO funk f. 13 |
| 532 | fills | New Orleans funk fill 14 | NO funk f. 14 | NO funk f. 14 |
| 534 | fills | Latin brazilian baiao fill 3 | Baiao fill 3 | Baiao fill 3 |
| 535 | fills | Funk rock fill 5 | Funk rock f. 5 | Funk rock f. 5 |
| 536 | fills | New Orleans funk fill 15 | NO funk f. 15 | NO funk f. 15 |
| 537 | fills | Hip hop fill 8 | Hip hop fill 8 | Hip hop fill 8 |
| 538 | fills | Rock fill 21 | Rock fill 21 | Rock fill 21 |
| 539 | fills | Funk rock fill 6 | Funk rock f. 6 | Funk rock f. 6 |
| 541 | fills | New Orleans funk fill 16 | NO funk f. 16 | NO funk f. 16 |
| 543 | fills | Rock fill 22 | Rock fill 22 | Rock fill 22 |
| 544 | fills | Latin samba fill 2 | Samba fill 2 | Samba fill 2 |
| 545 | fills | Latin brazilian baiao fill 4 | Baiao fill 4 | Baiao fill 4 |
| 546 | fills | Hip hop fill 9 | Hip hop fill 9 | Hip hop fill 9 |
| 547 | fills | Rock fill 23 | Rock fill 23 | Rock fill 23 |
| 10001 | intro | Kick on every beat | Kick on beats | Kick na doby |
| 10002 | intro | A steady right hand | Steady right | Pravá v pulsu |
| 10003 | intro | Snare on two and four | Snare on 2 & 4 | Snare na 2 a 4 |
| 10004 | intro | Kick, snare, kick, snare | Kick and snare | Kick a snare |
| 10005 | intro | Hands take turns | Taking turns | Střídání rukou |
| 10006 | intro | Kick and hat together | Kick with hat | Kick s hi-hat |
| 10007 | intro | Snare and hat together | Snare with hat | Snare s hi-hat |
| 10008 | intro | Your first groove | First groove | První groove |
| 10009 | intro | Eight steady hats | 8 steady hats | 8 úderů hi-hat |
| 10010 | intro | Hats with a kick anchor | Hats with kick | Hi-hat a kick |
| 10011 | intro | A complete backbeat | Full backbeat | Celý backbeat |
| 10012 | intro | A two-bar phrase | Two-bar phrase | Fráze 2 takty |
| 10013 | intro | Extra kick after two | Kick after two | Kick po době 2 |
| 10014 | intro | Extra kick after three | Kick after 3 | Kick po době 3 |
| 10015 | intro | Dance offbeats | Dance offbeats | Tanec na & |
| 10016 | intro | Dance with a clap | Dance & clap | Tanec s clapem |
| 10017 | intro | One open hat | One open hat | Open hi-hat |
| 10018 | intro | Strong and soft hats | Hat dynamics | Dynamika hat |
| 10019 | intro | A first sixteenth pair | 16th pair | První 16tiny |
| 10020 | intro | Rest without losing time | Rest in time | Pauza v pulsu |
| 10021 | intro | A one-beat snare fill | One-beat fill | Přechod 1 doby |
| 10022 | intro | A kick and snare answer | Kick and snare | Kick a snare |
| 10023 | intro | A short tom answer | Tom answer | Odpověď tomů |
| 10024 | intro | Groove, fill, return | Groove & fill | Groove a fill |
| 11001 | jersey | Jersey · the five-kick bounce | Jersey bounce | Jersey 5 kicků |
| 11002 | jersey | Jersey · backbeat bounce | Jersey back | Jersey back |
| 11003 | jersey | Jersey · right-hand anchor | Jersey anchor | Jersey opora |
| 11004 | jersey | Jersey · a snare answer | Jersey snare | Jersey snare |
| 11005 | jersey | Jersey · two-bar snare twist | Jersey 2-bar | Jersey 2 takty |
| 11006 | jersey | Jersey · groove and break | Jersey break | Jersey pauza |
| 12001 | footwork | Footwork · half-time pulse | Footwork half | Footwork půl |
| 12002 | footwork | Footwork · displaced kicks | Footwork kicks | Footwork kick |
| 12003 | footwork | Footwork · snare burst | Footwork burst | Footwork snare |
| 12004 | footwork | Footwork · triplet feel | Footwork 3lets | Footwork triol |
| 12005 | footwork | Footwork · hat response | Footwork hats | Footwork hat |
| 12006 | footwork | Footwork · two-bar talk | Footwork 2bar | Footwork 2 tak |
| 13001 | hardgroove | Hardgroove 1 · tom pickups | Hardgroove 1 | Hardgroove 1 |
| 13002 | hardgroove | Hardgroove 2 · open-hat drive | Hardgroove 2 | Hardgroove 2 |
| 13003 | hardgroove | Hardgroove 3 · clap accents | Hardgroove 3 | Hardgroove 3 |
| 13004 | hardgroove | Hardgroove 4 · the return | Hardgroove 4 | Hardgroove 4 |
| 14001 | broken-techno | Broken techno 1 · missing kick | Broken tech 1 | Broken tech 1 |
| 14002 | broken-techno | Broken techno 2 · rim pickup | Broken tech 2 | Broken tech 2 |
| 14003 | broken-techno | Broken techno 3 · two kicks | Broken tech 3 | Broken tech 3 |
| 14004 | broken-techno | Broken techno 4 · the return | Broken tech 4 | Broken tech 4 |
| 15001 | uk-club | UK funky 1 · syncopated rim | UK funky 1 | UK funky 1 |
| 15002 | uk-club | UK funky 2 · hats and rim | UK funky 2 | UK funky 2 |
| 15003 | uk-club | Speed garage 1 · the skippy top | Speed garage 1 | Speed garage 1 |
| 15004 | uk-club | Speed garage 2 · fill, restart | Speed garage 2 | Speed garage 2 |

## Files to read

`AGENTS.md`, `HomeScreen.swift` (`HomePadView`, `HomePadSubtitles`), `MIDIInput.swift` (line 87, network source name), `LessonData.swift` and `Resources/Data/*.json` (lesson titles), `en.lproj/Localizable.strings`, `cs.lproj/Localizable.strings`, ticket 181 (`docs/tickets/2026-11-11-181-back-arrow-and-home-pads.md`).

## Tests

1. `HomePadSubtitles.controller`: the network session returns "Network MIDI" / "Síťový MIDI"; a long device name is cut at a word boundary within the limit.
2. Every lesson (core, path, genre extensions, intro) has a Home line of at most 14 characters in English and in Czech (title or short name).
If an existing test enforces the old truncation, delete it.

## Acceptance criteria

- [x] English and Czech Home: every pad line is one line with no "…", including Continue after "Kick on every beat" and Controller with the network session.
- [x] Short names listed in the ticket for review.
- [x] All eight Home pads are still exactly the same size, in landscape and portrait.
- [x] Build and full test suite pass.

### Manual iPad checks for Jakub

Home in English and in Czech, landscape and portrait, with the network MIDI session connected and after playing "Kick on every beat": no "…" under any pad, pads all the same size, and the short names read well.

## Agent assignment

Gemini 3.8 Flash, thinking **high** (many short names to write in two languages). Fallback: Codex GPT-6.1 Sol, high.

## Done rule

Build, run the full test suite per `AGENTS.md`, commit, stop for Jakub's iPad check.
