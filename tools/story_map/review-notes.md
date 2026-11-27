# Story Map Manual Review Notes

Review of the unreviewed proposal produced by `tools/story_map/generate.py` against musical equivalence, instrumentation, technique focus, and guided progression order. Reference forks by `<stageId>[<nodeIndex>]` (0-based in the reviewed `SmackAPad/Resources/Data/story-map.json`, or proposal index where split).

## L1-groove
- **Proposal `[5]` (`[20, 160, 167]`) -> `K(20)` + `L1-groove[6]` (`[160, 167]`):** Split `20 Jazz swing 2` out as a keystone because its swing feel continues `10 Jazz swing 1`, leaving `160 House: offbeat open hat` and `167 Techno: kick and open hat` as a pure 4-on-the-floor Electronic open-hat fork.
- **Proposal `[11]` (`[22, 178]`) -> `K(22), K(178)`:** Split `22 Rock 5` (straight rock beat) and `178 Two-step garage` (syncopated UK garage two-step); different rhythmic feel and genre.
- **Proposal `[18]` (`[184, 29]`) + `K(31)` -> `K(184)` + `L1-groove[21]` (`[29, 31]`):** Split `184 Drum and bass two-step` out from `29 Rock 10`, and paired `29 Rock 10` with `31 Rock 12` (both 1-bar Rock, 75–120 BPM, 14 hits).

## L1-sixteenths
- **Proposal `[5]` (`[198, 42, 43]`) -> `K(198)` + `L1-sixteenths[6]` (`[42, 43]`):** Split `198 Dembow` (left-hand-only reggaeton ostinato) out from `42 Funk 3` and `43 Funk 4` (two-hand Funk with open hat).
- **Proposal `[7]` (`[59, 332]`) -> `K(59), K(332)`:** Split `59 Pop 1` (kick + snare + hat) and `332 Afro-Cuban calypso 1` (no kick, snare + hats only).
- **Proposal `[9]` (`[47, 48]`) -> `K(47), K(48)`:** Split `47 Hip hop 8` (kick + snare + hat) and `48 Funk 5` (no kick, two-hand snare + hats).
- **Proposal `[11]` (`[331, 190]`) -> `K(331), K(190)`:** Split `331 Latin reggaeton` (rim + kick) and `190 Boom bap with pushed kick` (snare + kick).
- **Proposal `[15]` (`[55, 61]`), `[18]` (`[56, 60]`), `[19]` (`K(50)`), `[20]` (`[53, 62]`) -> `K(55), K(56), K(60)` + `L1-sixteenths[24]` (`[50, 53]`) + `L1-sixteenths[25]` (`[61, 62]`):** Separated cross-genre Rock/Funk mismatches and paired same-genre 2-bar open-hat twins (`50 Funk 6` + `53 Funk 7` at 60–95 BPM; `61 Rock 26` + `62 Rock 27` at 65–102 BPM).

## L1-ghost
- **Proposal `[1]` (`[205, 208]`) -> `K(205), K(208)`:** Split `205 Country 2` (closed hat, 8 hits) and `208 Soul 3` (open hat + left-hand hat, 10 hits).
- **Proposal `[3]` (`[328, 330]`) -> `K(328), K(330)`:** Split `328 Latin brazilian bossa 1` (ride + crash) and `330 Middle Eastern 1` (hi-hat groove).

## L1-swing
- Unchanged (all 5 lessons stay keystones because `333 Reggae 1` vs `335 Reggae 2` differ by >25% in hit count, 7 vs 9).

## L1-fills
- **Proposal `[3]` (`[329, 30]`) -> `K(329), K(30)`:** Split `329 Afro-Cuban rhumba 1` (16th-note rim + tom) and `30 Rock 11` (eighth-note rock with ride, crash, and two toms).

## L2-groove
- **Proposal `[1]` (`[165, 13003]`), `[3]` (`[187, 14003]`), `[4]` (`K(13002)`), `[5]` (`[14002, 15002]`) -> all keystones in order (`13002 -> 13003`, `14002 -> 14003`, `15002 -> 15003`):** Electronic-path lessons are guided sequential builds ("one layer at a time"); kept them as ordered keystones rather than mixing them into cross-genre forks or inverting `Hardgroove 3` ahead of `Hardgroove 2`.

## L2-sixteenths
- **Proposal `[6]` (`[66, 200]`) -> `K(66), K(200)`:** Split `66 Rock 29` (ride) and `200 Dembow with rim and shaker`.
- **Proposal `[15]` (`[339, 81]`) + `[11]` (`K(336)`) -> `L2-sixteenths[12]` (`[336, 339]`) + `K(81)`:** Separated `339 Highlife 2` (kick + hi-hat, no snare) from `81 Rock 33` (kick + snare + ride), and paired `336 Highlife 1` with `339 Highlife 2` (both Highlife, 14 hits, 75–120 / 80–126 BPM).
- **Proposal `[24]` (`[86, 354]`) -> `K(86), K(354)`:** Split `86 Rock 35` and `354 Afrobeat 5` (open hat + right-hand snare).
- **Proposal `[28]` (`[93, 94]`) -> `K(93), K(94)`:** Split `93 Rock 38` (kick + low tom + snare, no hats) and `94 Rock 39` (hi-hat + open hat, no tom).

## L2-ghost
- **Proposal `[1]` (`[216, 222]`) -> `K(216), K(222)`:** Split `216 Dance disco 8` and `222 Rock 67` (different genres and tempos, 75–120 vs 85–130 BPM).
- **Proposal `[6]` (`[221, 351]`) -> `K(221), K(351)`:** Split `221 Funk 32` (2-bar open-hat funk) and `351 Latin brazilian ijexa 2` (2-bar ride ijexa).
- **Proposal `[9]` (`[348, 358]`) -> `K(348), K(358)`:** Split `348 Latin brazilian bossa 2` (rim, no snare) and `358 Middle Eastern 2` (snare, no rim).
- **Proposal `[10]` (`K(349)`) + `[11]` (`K(352)`) -> `L2-ghost[13]` (`[349, 352]`):** Paired `349 Latin brazilian ijexa 1` and `352 Latin brazilian baiao 1` (both 1-bar Brazilian Latin ghost-note ride grooves at 70–108 / 70–110 BPM, 14 vs 16 hits).

## L2-swing
- **Proposal `[1]` (`[276, 288]`) -> `K(276), K(288)`:** Split `276 Jazz swing 9` (kick + low tom, ghost notes) and `288 Jazz swing 10` (kick + two-hand snare, no ghost notes).
- **Proposal `[3]` (`[338, 271]`) -> `K(338), K(271)`:** Split `338 Reggae 3` (hi-hat) and `271 Punk 12` (ride).
- **Proposal `[11]` (`[282, 289]`) + `[12]` (`K(283)`) + `[13]` (`K(284)`) -> `K(282), K(289)` + `L2-swing[14]` (`[283, 284]`):** Split `282 Rock 77` (crash) from `289 Rock shuffle 3` (open hat), and paired `283 Rock 78` with `284 Rock 79` (both 2-bar Rock shuffles, 60–96 BPM, 35 vs 31 hits).

## L2-fills
- **Proposal `[1]` (`[69, 217]`) -> `K(69), K(217)`:** Split `69 Punk 1` (toms, no ghost notes) and `217 Dance disco 9` (ghost notes + ride).
- **Proposal `[9]` (`[457, 451]`) -> `K(457), K(451)`:** Split `457 New Orleans funk fill 2` (ride) and `451 Rock fill 2`.
- **Proposal `[11]` (`[446, 461]`) -> `K(446), K(461)`:** Split `446 Latin brazilian baiao fill 1` (no ghost notes) and `461 New Orleans funk fill 3` (ghost notes).
- **Proposal `[13]` (`[447, 452]`) + `[10]` (`K(449)`) -> `K(447)` + `L2-fills[12]` (`[449, 452]`):** Split `447 Latin samba fill 1` (rim, no toms) from `452 Rock fill 3`, and paired `449 Rock fill 1` with `452 Rock fill 3` (both 2-bar Rock tom fills, 70–115 BPM, 22 vs 23 hits).

## L3-groove
- Unchanged (all 5 lessons stay keystones: 3 guided 4-bar electronic-path finales and 2 Rock 1-bar grooves at 140 vs 115 BPM).

## L3-sixteenths
- **Proposal `[1]` (`[97, 105, 109]`) -> `K(97)` + `L3-sixteenths[2]` (`[105, 109]`):** Split `97 Rock indie 3` (ride) out, leaving `105 Funk 23` and `109 Funk latin` as a pure Funk open-hat fork.
- **Proposal `[3]` (`[180, 98]`) -> `K(180), K(98)`:** Split `180 Two-step garage with shaker` (shaker + open hat) and `98 Punk 2` (hi-hat).
- **Proposal `[6]` (`[111, 360]`) -> `K(111), K(360)`:** Split `111 Hip hop 10` and `360 Afrobeat 7`.
- **Proposal `[10]` (`[361, 367]`) -> `K(361), K(367)`:** Split `361 Latin brazilian baiao 2` (left-hand only) and `367 Afrobeat 10` (two-hand open hat).
- **Proposal `[16]` (`[113, 372]`) -> `K(113), K(372)`:** Split `113 Rock 49` (snare) and `372 Latin brazilian baiao 3` (rim).
- **Proposal `[18]` (`[116, 370]`) + `[17]` (`K(369)`) -> `K(116)` + `L3-sixteenths[23]` (`[369, 370]`):** Split `116 Rock 50` out and paired `369 Afrobeat 11` with `370 Afrobeat 12` (both Afrobeat, 70–114 BPM, 16 vs 17 hits).

## L3-ghost
- **Proposal `[1]` (`[224, 364]`) -> `K(224), K(364)`:** Split `224 Funk 34` (ride + open hat) and `364 Latin brazilian samba 1` (crash + low tom).
- **Proposal `[5]` (`[228, 366, 373]`) -> `K(228), K(366), K(373)`:** Split three distinct idioms and instrumentations (`228 Jazz funk` rim + ride, `366 Afro-Cuban calypso 2` crash + ride + rim, `373 Afrobeat 13` open hat + hi-hat).

## L3-swing
- **Proposal `[4]` (`[294, 297]`) -> `K(294), K(297)`:** Split `294 Rock shuffle 5` (ghost notes on ride) and `297 Rock 84` (open hat, no ghost notes).

## L3-fills
- **Proposal `[4]` (`[468, 471]`) -> `K(468), K(471)`:** Split `468 Funk fill 2` (ghost notes + rim) and `471 Jazz fusion fill 2` (no ghost notes).
- **Proposal `[6]` (`[101, 377]`) -> `K(101), K(377)`:** Split `101 Rock 42` (crash + toms) and `377 Afro-Cuban calypso 4` (rim + ride).
- **Proposal `[8]` (`[498, 470]`) -> `K(498), K(470)`:** Split `498 Country fill 3` (ghost notes + toms) and `470 Gospel fill 1` (open hat, no ghost notes).
- **Proposal `[10]` (`[475, 472]`) -> `K(475), K(472)`:** Split `475 Hip hop fill 2` (ghost notes) and `472 Soul fill 3` (ride + toms, no ghost notes).
- **Proposal `[15]` (`[380, 115]`) -> `K(380), K(115)`:** Split `380 Afro-Cuban calypso 5` (ghost notes + ride) and `115 Rock prog 1` (no ghost notes).
- **Proposal `[17]` (`[485, 479]`) -> `K(485), K(479)`:** Split `485 Jazz funk fill 1` (ghost notes + rim) and `479 Funk fast fill 1` (no ghost notes).
- **Proposal `[21]` (`[488, 487]`) -> `K(488), K(487)`:** Split `488 New Orleans funk fill 5` (ghost notes) and `487 Funk rock fill 3` (open hat, no ghost notes).
- **Proposal `[23]` (`[489, 495]`) -> `K(489), K(495)`:** Split `489 New Orleans funk fill 6` (no ghost notes) and `495 New Orleans funk fill 7` (ghost notes + open hat + ride).
- **Proposal `[30]` (`[493, 466]`) -> `K(493), K(466)`:** Split `493 Funk fast fill 2` (ghost notes + open hat) and `466 Rock fill 9` (no ghost notes).
- **Proposal `[35]` (`[482, 483]`) -> `K(482), K(483)`:** Split `482 Punk fill 1` (ghost notes + ride + rim) and `483 Punk fill 2` (no ghost notes, high + low tom).

## L4-sixteenths
- **Proposal `[2]` (`[125, 119]`) -> `K(125), K(119)`:** Split `125 Rock 54` (crash) and `119 Hip hop 13` (open hat).
- **Proposal `[5]` (`[397, 400]`) -> `K(397), K(400)`:** Split `397 Latin brazilian songo 1` (snare + ride) and `400 Latin 6` (rim + hi-hat, no snare).

## L4-ghost
- **Proposal `[1]` (`[230, 231]`) -> `K(230), K(231)`:** Split `230 Jazz march 1` (two-hand snare) and `231 Hip hop 21` (hi-hat).
- **Proposal `[4]` (`[233, 238]`) -> `K(233), K(238)`:** Split `233 Jazz march 2` (has kick) and `238 Jazz march 4` (no kick, snare-only march).
- **Proposal `[6]` (`[384, 386]`) -> `K(384), K(386)`:** Split `384 Latin 5` (open hat, 16 hits) and `386 Afrobeat 15` (ride, 20 hits).

## L4-swing
- **Proposal `[6]` (`[312, 321]`) -> `K(312), K(321)`:** Split `312 Rock 88` (ghost notes) and `321 Rock shuffle 10` (no ghost notes).

## L4-fills
- **Proposal `[4]` (`[506, 502]`) -> `K(506), K(502)`:** Split `506 Hip hop fill 6` (no ghost notes, 42 hits) and `502 Soul fill 6` (ghost notes + rim + ride, 34 hits).
- **Proposal `[6]` (`[387, 388]`) -> `K(387), K(388)`:** Split `387 Brazilian sambareggae 3` (ghost notes + two kicks + low tom) and `388 Afro-Cuban 4` (rim + ride + high tom, no ghost notes).
- **Proposal `[8]` (`[501, 509]`) + `[13]` (`[504, 520]`) -> `K(501), K(504)` + `L4-fills[17]` (`[509, 520]`):** Split `501 Jazz fusion fill 3` (no ghost notes) and `504 Funk fill 5` (no high tom/ride/open hat), and paired `509 New Orleans funk fill 8` with `520 New Orleans funk fill 9` (both 3-bar New Orleans funk ghost-note tom fills at 60–93 BPM, 39 vs 43 hits).
- **Proposal `[11]` (`[138, 393]`) -> `K(138), K(393)`:** Split `138 Rock 60` (snare + ride) and `393 Afro-Cuban calypso 10` (rim + open hat).
- **Proposal `[31]` (`[510, 523]`) -> `K(510), K(523)`:** Split `510 Rock fill 16` (straight feel, 34 hits) and `523 Rock halftime fill 4` (halftime feel, rim + high/low tom, 40 hits).

## L5-sixteenths
- **Proposal `[1]` (`[142, 145]`) -> `K(142), K(145)`:** Split `142 Hip hop 17` (ride) and `145 Funk 27` (open hat).
- **Proposal `[3]` (`[148, 406, 416]`) -> `K(148)` + `L5-sixteenths[5]` (`[406, 416]`):** Split `148 Jazz linear 1` (linear snare + ride, no kick) out from `406 Latin 9` and `416 Highlife 4`.
- **Proposal `[5]` (`[143, 424, 426]`) -> `K(143)` + `L5-sixteenths[8]` (`[424, 426]`):** Split `143 Hip hop 18` (snare) out from `424 Afrobeat 19` and `426 Afrobeat 20` (both Afrobeat rim + hi-hat).
- **Proposal `[10]` (`[158, 425]`) -> `K(158), K(425)`:** Split `158 Rock prog 6` (low tom + right-hand snare) and `425 Highlife 5` (open hat + hi-hat).

## L5-ghost
- **Proposal `[3]` (`[247, 243]`) -> `K(247), K(243)`:** Split `247 Funk 36` (hi-hat + right-hand snare) and `243 Rock 69` (ride).
- **Proposal `[5]` (`[408, 250]`) -> `K(408), K(250)`:** Split `408 Latin brazilian samba 2` (low tom + ride) and `250 Funk 37` (open hat + hi-hat + snare).
- **Proposal `[9]` (`[252, 427]`) -> `K(252), K(427)`:** Split `252 Soul 5` (snare + hi-hat) and `427 Afrobeat 21` (rim + ride).
- **Proposal `[15]` (`[259, 431]`) + `[23]` (`K(435)`) -> `K(259)` + `L5-ghost[26]` (`[431, 435]`):** Split `259 Jazz march 6` (two-hand snare) out and paired `431 Latin brazilian songo 3` with `435 Latin brazilian songo 4` (both 1-bar Brazilian songo ghost-note ride patterns at 70–112 BPM, 18 vs 20 hits).
- **Proposal `[25]` (`K(439)`) + `[26]` (`K(441)`) -> `L5-ghost[28]` (`[439, 441]`):** Paired `439 Latin brazilian samba 3` and `441 Latin brazilian baiao 4` (both 1-bar Brazilian ghost-note grooves at 55–89 / 60–95 BPM, 20 vs 22 hits).

## L5-swing
- Unchanged (`[409, 417]` Latin chacarera 6 & 8).

## L5-fills
- **Proposal `[1]` (`[154, 152, 153]`) -> `K(154)` + `L5-fills[2]` (`[152, 153]`):** Split `154 Jazz linear 2` (linear ride + kick + toms) out from `152 Rock prog 2` and `153 Rock prog 3`.
- **Proposal `[4]` (`[537, 532, 536]`) -> `K(537)` + `L5-fills[6]` (`[532, 536]`):** Split `537 Hip hop fill 8` out from `532 New Orleans funk fill 14` and `536 New Orleans funk fill 15`.
- **Proposal `[7]` (`[535, 539]`) -> `K(535), K(539)`:** Split `535 Funk rock fill 5` (ghost notes, no high tom) and `539 Funk rock fill 6` (no ghost notes, rim + high tom).
- **Proposal `[12]` (`[157, 254]`) + `[15]` (`K(253)`) -> `K(157)` + `L5-fills[19]` (`[253, 254]`):** Split `157 Rock prog 5` (open hat, no ghost notes) out and paired `253 Rock prog 7` with `254 Rock prog 8` (both Rock prog ghost-note + tom patterns at 80–125 BPM, 18 vs 20 hits).
- **Proposal `[14]` (`[420, 433]`) -> `K(420), K(433)`:** Split `420 Latin 11` (ride + snare, no ghost notes) and `433 Latin 16` (rim + ghost notes, no snare).
- **Proposal `[19]` (`[432, 437]`) -> `K(432), K(437)`:** Split `432 Highlife 6` (snare + ride, no ghost notes) and `437 Latin 17` (rim + ghost notes).
- **Proposal `[22]` (`[434, 534]`) -> `K(434), K(534)`:** Split `434 Brazilian sambareggae 5` (2-bar groove, `cat == "world"`) and `534 Latin brazilian baiao fill 3` (groove + fill, `cat == "fills"`).
- **Proposal `[20]` (`K(540)`) + `[21]` (`K(542)`) -> `L5-fills[25]` (`[540, 542]`):** Paired `540 Punk fill 5` and `542 Punk fill 6` (both 2-bar Punk fills, 80–128 BPM, 33 vs 34 hits, ghost notes + ride + toms).
- **Proposal `[23]` (`K(543)`) + `[25]` (`K(547)`) -> `L5-fills[28]` (`[543, 547]`):** Paired `543 Rock fill 22` and `547 Rock fill 23` (both 3-bar Rock fills, 70–110 BPM, 49 vs 52 hits, ghost notes).
