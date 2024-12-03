--
-- PostgreSQL database dump
--

-- Dumped from database version 16.1
-- Dumped by pg_dump version 16.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: myschema; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA myschema;


ALTER SCHEMA myschema OWNER TO postgres;

--
-- Name: audit_log(); Type: FUNCTION; Schema: myschema; Owner: springstudent
--

CREATE FUNCTION myschema.audit_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	insert into myschema.task_audit (task_id, entry_date, operation)
	values (new.task_id, current_date, 'INSERT');
	return new;
end; 
$$;


ALTER FUNCTION myschema.audit_log() OWNER TO springstudent;

--
-- Name: event_trigger_function(); Type: FUNCTION; Schema: myschema; Owner: springstudent
--

CREATE FUNCTION myschema.event_trigger_function() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
begin
	raise info 'Event = %, Tag = %', tg_event, tg_tag;
end $$;


ALTER FUNCTION myschema.event_trigger_function() OWNER TO springstudent;

--
-- Name: inserter(); Type: PROCEDURE; Schema: myschema; Owner: springstudent
--

CREATE PROCEDURE myschema.inserter()
    LANGUAGE plpgsql
    AS $$
begin
	truncate table myschema.index_trial_tasks;
	for i in 1..1000 loop
		insert into myschema.index_trial_tasks values (
			i, 'tt' || i, 100 + i
		);
	end loop;
	commit;
end
$$;


ALTER PROCEDURE myschema.inserter() OWNER TO springstudent;

--
-- Name: inserter2(); Type: FUNCTION; Schema: myschema; Owner: springstudent
--

CREATE FUNCTION myschema.inserter2() RETURNS void
    LANGUAGE plpgsql
    AS $$
begin
	truncate table myschema.index_trial_tasks;
	for i in 1..1000 loop
		insert into myschema.index_trial_tasks values (
			i, 'tt' || i, 100 + i
		);
	end loop;
end
$$;


ALTER FUNCTION myschema.inserter2() OWNER TO springstudent;

--
-- Name: parameterized_returner(integer); Type: FUNCTION; Schema: myschema; Owner: springstudent
--

CREATE FUNCTION myschema.parameterized_returner(times integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
declare
	counter int = 1;
begin
	counter = counter * times;
	return counter;
end;
$$;


ALTER FUNCTION myschema.parameterized_returner(times integer) OWNER TO springstudent;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: index_trial_tasks; Type: TABLE; Schema: myschema; Owner: springstudent
--

CREATE TABLE myschema.index_trial_tasks (
    task_id integer NOT NULL,
    task_title character varying(20) NOT NULL,
    user_id integer
);


ALTER TABLE myschema.index_trial_tasks OWNER TO springstudent;

--
-- Name: task_audit; Type: TABLE; Schema: myschema; Owner: springstudent
--

CREATE TABLE myschema.task_audit (
    log_id integer NOT NULL,
    task_id integer NOT NULL,
    entry_date date,
    operation character varying(10)
);


ALTER TABLE myschema.task_audit OWNER TO springstudent;

--
-- Name: task_audit_log_id_seq; Type: SEQUENCE; Schema: myschema; Owner: springstudent
--

CREATE SEQUENCE myschema.task_audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE myschema.task_audit_log_id_seq OWNER TO springstudent;

--
-- Name: task_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: myschema; Owner: springstudent
--

ALTER SEQUENCE myschema.task_audit_log_id_seq OWNED BY myschema.task_audit.log_id;


--
-- Name: tasks; Type: TABLE; Schema: myschema; Owner: springstudent
--

CREATE TABLE myschema.tasks (
    task_id integer NOT NULL,
    task_name character varying(20) NOT NULL,
    task_desc character varying(20) NOT NULL,
    task_type character varying(10) DEFAULT NULL::character varying,
    parent integer
);


ALTER TABLE myschema.tasks OWNER TO springstudent;

--
-- Name: tasks_archive; Type: TABLE; Schema: myschema; Owner: springstudent
--

CREATE TABLE myschema.tasks_archive (
    task_id integer NOT NULL,
    task_name character varying(20) NOT NULL,
    task_desc character varying(20) NOT NULL,
    task_type character varying(10) DEFAULT NULL::character varying,
    parent integer
);


ALTER TABLE myschema.tasks_archive OWNER TO springstudent;

--
-- Name: authorities; Type: TABLE; Schema: public; Owner: springstudent
--

CREATE TABLE public.authorities (
    username character varying(50) NOT NULL,
    authority character varying(50) NOT NULL
);


ALTER TABLE public.authorities OWNER TO springstudent;

--
-- Name: counter; Type: TABLE; Schema: public; Owner: springstudent
--

CREATE TABLE public.counter (
    count bigint
);


ALTER TABLE public.counter OWNER TO springstudent;

--
-- Name: custom_authorities; Type: TABLE; Schema: public; Owner: springstudent
--

CREATE TABLE public.custom_authorities (
    userid character varying(50) NOT NULL,
    role character varying(50) NOT NULL
);


ALTER TABLE public.custom_authorities OWNER TO springstudent;

--
-- Name: custom_space_table; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custom_space_table (
    id integer,
    name character varying(10)
);


ALTER TABLE public.custom_space_table OWNER TO postgres;

--
-- Name: custom_users; Type: TABLE; Schema: public; Owner: springstudent
--

CREATE TABLE public.custom_users (
    userid character varying(50) NOT NULL,
    pwd character varying(100) NOT NULL,
    age integer NOT NULL,
    enabled character(1) NOT NULL
);


ALTER TABLE public.custom_users OWNER TO springstudent;

--
-- Name: greeting; Type: TABLE; Schema: public; Owner: springstudent
--

CREATE TABLE public.greeting (
    id integer NOT NULL,
    message character varying(45) NOT NULL,
    student_id integer NOT NULL
);


ALTER TABLE public.greeting OWNER TO springstudent;

--
-- Name: greeting_id_seq; Type: SEQUENCE; Schema: public; Owner: springstudent
--

CREATE SEQUENCE public.greeting_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.greeting_id_seq OWNER TO springstudent;

--
-- Name: greeting_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: springstudent
--

ALTER SEQUENCE public.greeting_id_seq OWNED BY public.greeting.id;


--
-- Name: student; Type: TABLE; Schema: public; Owner: springstudent
--

CREATE TABLE public.student (
    id integer NOT NULL,
    first_name character varying(45) DEFAULT NULL::character varying,
    last_name character varying(45) DEFAULT NULL::character varying,
    email character varying(45) DEFAULT NULL::character varying
);


ALTER TABLE public.student OWNER TO springstudent;

--
-- Name: student_id_seq; Type: SEQUENCE; Schema: public; Owner: springstudent
--

CREATE SEQUENCE public.student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_id_seq OWNER TO springstudent;

--
-- Name: student_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: springstudent
--

ALTER SEQUENCE public.student_id_seq OWNED BY public.student.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: springstudent
--

CREATE TABLE public.users (
    username character varying(50) NOT NULL,
    password character varying(100) NOT NULL,
    enabled integer NOT NULL
);


ALTER TABLE public.users OWNER TO springstudent;

--
-- Name: task_audit log_id; Type: DEFAULT; Schema: myschema; Owner: springstudent
--

ALTER TABLE ONLY myschema.task_audit ALTER COLUMN log_id SET DEFAULT nextval('myschema.task_audit_log_id_seq'::regclass);


--
-- Name: greeting id; Type: DEFAULT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.greeting ALTER COLUMN id SET DEFAULT nextval('public.greeting_id_seq'::regclass);


--
-- Name: student id; Type: DEFAULT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.student ALTER COLUMN id SET DEFAULT nextval('public.student_id_seq'::regclass);


--
-- Data for Name: index_trial_tasks; Type: TABLE DATA; Schema: myschema; Owner: springstudent
--

COPY myschema.index_trial_tasks (task_id, task_title, user_id) FROM stdin;
1	tt1	101
2	tt2	102
3	tt3	103
4	tt4	104
5	tt5	105
6	tt6	106
7	tt7	107
8	tt8	108
9	tt9	109
10	tt10	110
11	tt11	111
12	tt12	112
13	tt13	113
14	tt14	114
15	tt15	115
16	tt16	116
17	tt17	117
18	tt18	118
19	tt19	119
20	tt20	120
21	tt21	121
22	tt22	122
23	tt23	123
24	tt24	124
25	tt25	125
26	tt26	126
27	tt27	127
28	tt28	128
29	tt29	129
30	tt30	130
31	tt31	131
32	tt32	132
33	tt33	133
34	tt34	134
35	tt35	135
36	tt36	136
37	tt37	137
38	tt38	138
39	tt39	139
40	tt40	140
41	tt41	141
42	tt42	142
43	tt43	143
44	tt44	144
45	tt45	145
46	tt46	146
47	tt47	147
48	tt48	148
49	tt49	149
50	tt50	150
51	tt51	151
52	tt52	152
53	tt53	153
54	tt54	154
55	tt55	155
56	tt56	156
57	tt57	157
58	tt58	158
59	tt59	159
60	tt60	160
61	tt61	161
62	tt62	162
63	tt63	163
64	tt64	164
65	tt65	165
66	tt66	166
67	tt67	167
68	tt68	168
69	tt69	169
70	tt70	170
71	tt71	171
72	tt72	172
73	tt73	173
74	tt74	174
75	tt75	175
76	tt76	176
77	tt77	177
78	tt78	178
79	tt79	179
80	tt80	180
81	tt81	181
82	tt82	182
83	tt83	183
84	tt84	184
85	tt85	185
86	tt86	186
87	tt87	187
88	tt88	188
89	tt89	189
90	tt90	190
91	tt91	191
92	tt92	192
93	tt93	193
94	tt94	194
95	tt95	195
96	tt96	196
97	tt97	197
98	tt98	198
99	tt99	199
100	tt100	200
101	tt101	201
102	tt102	202
103	tt103	203
104	tt104	204
105	tt105	205
106	tt106	206
107	tt107	207
108	tt108	208
109	tt109	209
110	tt110	210
111	tt111	211
112	tt112	212
113	tt113	213
114	tt114	214
115	tt115	215
116	tt116	216
117	tt117	217
118	tt118	218
119	tt119	219
120	tt120	220
121	tt121	221
122	tt122	222
123	tt123	223
124	tt124	224
125	tt125	225
126	tt126	226
127	tt127	227
128	tt128	228
129	tt129	229
130	tt130	230
131	tt131	231
132	tt132	232
133	tt133	233
134	tt134	234
135	tt135	235
136	tt136	236
137	tt137	237
138	tt138	238
139	tt139	239
140	tt140	240
141	tt141	241
142	tt142	242
143	tt143	243
144	tt144	244
145	tt145	245
146	tt146	246
147	tt147	247
148	tt148	248
149	tt149	249
150	tt150	250
151	tt151	251
152	tt152	252
153	tt153	253
154	tt154	254
155	tt155	255
156	tt156	256
157	tt157	257
158	tt158	258
159	tt159	259
160	tt160	260
161	tt161	261
162	tt162	262
163	tt163	263
164	tt164	264
165	tt165	265
166	tt166	266
167	tt167	267
168	tt168	268
169	tt169	269
170	tt170	270
171	tt171	271
172	tt172	272
173	tt173	273
174	tt174	274
175	tt175	275
176	tt176	276
177	tt177	277
178	tt178	278
179	tt179	279
180	tt180	280
181	tt181	281
182	tt182	282
183	tt183	283
184	tt184	284
185	tt185	285
186	tt186	286
187	tt187	287
188	tt188	288
189	tt189	289
190	tt190	290
191	tt191	291
192	tt192	292
193	tt193	293
194	tt194	294
195	tt195	295
196	tt196	296
197	tt197	297
198	tt198	298
199	tt199	299
200	tt200	300
201	tt201	301
202	tt202	302
203	tt203	303
204	tt204	304
205	tt205	305
206	tt206	306
207	tt207	307
208	tt208	308
209	tt209	309
210	tt210	310
211	tt211	311
212	tt212	312
213	tt213	313
214	tt214	314
215	tt215	315
216	tt216	316
217	tt217	317
218	tt218	318
219	tt219	319
220	tt220	320
221	tt221	321
222	tt222	322
223	tt223	323
224	tt224	324
225	tt225	325
226	tt226	326
227	tt227	327
228	tt228	328
229	tt229	329
230	tt230	330
231	tt231	331
232	tt232	332
233	tt233	333
234	tt234	334
235	tt235	335
236	tt236	336
237	tt237	337
238	tt238	338
239	tt239	339
240	tt240	340
241	tt241	341
242	tt242	342
243	tt243	343
244	tt244	344
245	tt245	345
246	tt246	346
247	tt247	347
248	tt248	348
249	tt249	349
250	tt250	350
251	tt251	351
252	tt252	352
253	tt253	353
254	tt254	354
255	tt255	355
256	tt256	356
257	tt257	357
258	tt258	358
259	tt259	359
260	tt260	360
261	tt261	361
262	tt262	362
263	tt263	363
264	tt264	364
265	tt265	365
266	tt266	366
267	tt267	367
268	tt268	368
269	tt269	369
270	tt270	370
271	tt271	371
272	tt272	372
273	tt273	373
274	tt274	374
275	tt275	375
276	tt276	376
277	tt277	377
278	tt278	378
279	tt279	379
280	tt280	380
281	tt281	381
282	tt282	382
283	tt283	383
284	tt284	384
285	tt285	385
286	tt286	386
287	tt287	387
288	tt288	388
289	tt289	389
290	tt290	390
291	tt291	391
292	tt292	392
293	tt293	393
294	tt294	394
295	tt295	395
296	tt296	396
297	tt297	397
298	tt298	398
299	tt299	399
300	tt300	400
301	tt301	401
302	tt302	402
303	tt303	403
304	tt304	404
305	tt305	405
306	tt306	406
307	tt307	407
308	tt308	408
309	tt309	409
310	tt310	410
311	tt311	411
312	tt312	412
313	tt313	413
314	tt314	414
315	tt315	415
316	tt316	416
317	tt317	417
318	tt318	418
319	tt319	419
320	tt320	420
321	tt321	421
322	tt322	422
323	tt323	423
324	tt324	424
325	tt325	425
326	tt326	426
327	tt327	427
328	tt328	428
329	tt329	429
330	tt330	430
331	tt331	431
332	tt332	432
333	tt333	433
334	tt334	434
335	tt335	435
336	tt336	436
337	tt337	437
338	tt338	438
339	tt339	439
340	tt340	440
341	tt341	441
342	tt342	442
343	tt343	443
344	tt344	444
345	tt345	445
346	tt346	446
347	tt347	447
348	tt348	448
349	tt349	449
350	tt350	450
351	tt351	451
352	tt352	452
353	tt353	453
354	tt354	454
355	tt355	455
356	tt356	456
357	tt357	457
358	tt358	458
359	tt359	459
360	tt360	460
361	tt361	461
362	tt362	462
363	tt363	463
364	tt364	464
365	tt365	465
366	tt366	466
367	tt367	467
368	tt368	468
369	tt369	469
370	tt370	470
371	tt371	471
372	tt372	472
373	tt373	473
374	tt374	474
375	tt375	475
376	tt376	476
377	tt377	477
378	tt378	478
379	tt379	479
380	tt380	480
381	tt381	481
382	tt382	482
383	tt383	483
384	tt384	484
385	tt385	485
386	tt386	486
387	tt387	487
388	tt388	488
389	tt389	489
390	tt390	490
391	tt391	491
392	tt392	492
393	tt393	493
394	tt394	494
395	tt395	495
396	tt396	496
397	tt397	497
398	tt398	498
399	tt399	499
400	tt400	500
401	tt401	501
402	tt402	502
403	tt403	503
404	tt404	504
405	tt405	505
406	tt406	506
407	tt407	507
408	tt408	508
409	tt409	509
410	tt410	510
411	tt411	511
412	tt412	512
413	tt413	513
414	tt414	514
415	tt415	515
416	tt416	516
417	tt417	517
418	tt418	518
419	tt419	519
420	tt420	520
421	tt421	521
422	tt422	522
423	tt423	523
424	tt424	524
425	tt425	525
426	tt426	526
427	tt427	527
428	tt428	528
429	tt429	529
430	tt430	530
431	tt431	531
432	tt432	532
433	tt433	533
434	tt434	534
435	tt435	535
436	tt436	536
437	tt437	537
438	tt438	538
439	tt439	539
440	tt440	540
441	tt441	541
442	tt442	542
443	tt443	543
444	tt444	544
445	tt445	545
446	tt446	546
447	tt447	547
448	tt448	548
449	tt449	549
450	tt450	550
451	tt451	551
452	tt452	552
453	tt453	553
454	tt454	554
455	tt455	555
456	tt456	556
457	tt457	557
458	tt458	558
459	tt459	559
460	tt460	560
461	tt461	561
462	tt462	562
463	tt463	563
464	tt464	564
465	tt465	565
466	tt466	566
467	tt467	567
468	tt468	568
469	tt469	569
470	tt470	570
471	tt471	571
472	tt472	572
473	tt473	573
474	tt474	574
475	tt475	575
476	tt476	576
477	tt477	577
478	tt478	578
479	tt479	579
480	tt480	580
481	tt481	581
482	tt482	582
483	tt483	583
484	tt484	584
485	tt485	585
486	tt486	586
487	tt487	587
488	tt488	588
489	tt489	589
490	tt490	590
491	tt491	591
492	tt492	592
493	tt493	593
494	tt494	594
495	tt495	595
496	tt496	596
497	tt497	597
498	tt498	598
499	tt499	599
500	tt500	600
501	tt501	601
502	tt502	602
503	tt503	603
504	tt504	604
505	tt505	605
506	tt506	606
507	tt507	607
508	tt508	608
509	tt509	609
510	tt510	610
511	tt511	611
512	tt512	612
513	tt513	613
514	tt514	614
515	tt515	615
516	tt516	616
517	tt517	617
518	tt518	618
519	tt519	619
520	tt520	620
521	tt521	621
522	tt522	622
523	tt523	623
524	tt524	624
525	tt525	625
526	tt526	626
527	tt527	627
528	tt528	628
529	tt529	629
530	tt530	630
531	tt531	631
532	tt532	632
533	tt533	633
534	tt534	634
535	tt535	635
536	tt536	636
537	tt537	637
538	tt538	638
539	tt539	639
540	tt540	640
541	tt541	641
542	tt542	642
543	tt543	643
544	tt544	644
545	tt545	645
546	tt546	646
547	tt547	647
548	tt548	648
549	tt549	649
550	tt550	650
551	tt551	651
552	tt552	652
553	tt553	653
554	tt554	654
555	tt555	655
556	tt556	656
557	tt557	657
558	tt558	658
559	tt559	659
560	tt560	660
561	tt561	661
562	tt562	662
563	tt563	663
564	tt564	664
565	tt565	665
566	tt566	666
567	tt567	667
568	tt568	668
569	tt569	669
570	tt570	670
571	tt571	671
572	tt572	672
573	tt573	673
574	tt574	674
575	tt575	675
576	tt576	676
577	tt577	677
578	tt578	678
579	tt579	679
580	tt580	680
581	tt581	681
582	tt582	682
583	tt583	683
584	tt584	684
585	tt585	685
586	tt586	686
587	tt587	687
588	tt588	688
589	tt589	689
590	tt590	690
591	tt591	691
592	tt592	692
593	tt593	693
594	tt594	694
595	tt595	695
596	tt596	696
597	tt597	697
598	tt598	698
599	tt599	699
600	tt600	700
601	tt601	701
602	tt602	702
603	tt603	703
604	tt604	704
605	tt605	705
606	tt606	706
607	tt607	707
608	tt608	708
609	tt609	709
610	tt610	710
611	tt611	711
612	tt612	712
613	tt613	713
614	tt614	714
615	tt615	715
616	tt616	716
617	tt617	717
618	tt618	718
619	tt619	719
620	tt620	720
621	tt621	721
622	tt622	722
623	tt623	723
624	tt624	724
625	tt625	725
626	tt626	726
627	tt627	727
628	tt628	728
629	tt629	729
630	tt630	730
631	tt631	731
632	tt632	732
633	tt633	733
634	tt634	734
635	tt635	735
636	tt636	736
637	tt637	737
638	tt638	738
639	tt639	739
640	tt640	740
641	tt641	741
642	tt642	742
643	tt643	743
644	tt644	744
645	tt645	745
646	tt646	746
647	tt647	747
648	tt648	748
649	tt649	749
650	tt650	750
651	tt651	751
652	tt652	752
653	tt653	753
654	tt654	754
655	tt655	755
656	tt656	756
657	tt657	757
658	tt658	758
659	tt659	759
660	tt660	760
661	tt661	761
662	tt662	762
663	tt663	763
664	tt664	764
665	tt665	765
666	tt666	766
667	tt667	767
668	tt668	768
669	tt669	769
670	tt670	770
671	tt671	771
672	tt672	772
673	tt673	773
674	tt674	774
675	tt675	775
676	tt676	776
677	tt677	777
678	tt678	778
679	tt679	779
680	tt680	780
681	tt681	781
682	tt682	782
683	tt683	783
684	tt684	784
685	tt685	785
686	tt686	786
687	tt687	787
688	tt688	788
689	tt689	789
690	tt690	790
691	tt691	791
692	tt692	792
693	tt693	793
694	tt694	794
695	tt695	795
696	tt696	796
697	tt697	797
698	tt698	798
699	tt699	799
700	tt700	800
701	tt701	801
702	tt702	802
703	tt703	803
704	tt704	804
705	tt705	805
706	tt706	806
707	tt707	807
708	tt708	808
709	tt709	809
710	tt710	810
711	tt711	811
712	tt712	812
713	tt713	813
714	tt714	814
715	tt715	815
716	tt716	816
717	tt717	817
718	tt718	818
719	tt719	819
720	tt720	820
721	tt721	821
722	tt722	822
723	tt723	823
724	tt724	824
725	tt725	825
726	tt726	826
727	tt727	827
728	tt728	828
729	tt729	829
730	tt730	830
731	tt731	831
732	tt732	832
733	tt733	833
734	tt734	834
735	tt735	835
736	tt736	836
737	tt737	837
738	tt738	838
739	tt739	839
740	tt740	840
741	tt741	841
742	tt742	842
743	tt743	843
744	tt744	844
745	tt745	845
746	tt746	846
747	tt747	847
748	tt748	848
749	tt749	849
750	tt750	850
751	tt751	851
752	tt752	852
753	tt753	853
754	tt754	854
755	tt755	855
756	tt756	856
757	tt757	857
758	tt758	858
759	tt759	859
760	tt760	860
761	tt761	861
762	tt762	862
763	tt763	863
764	tt764	864
765	tt765	865
766	tt766	866
767	tt767	867
768	tt768	868
769	tt769	869
770	tt770	870
771	tt771	871
772	tt772	872
773	tt773	873
774	tt774	874
775	tt775	875
776	tt776	876
777	tt777	877
778	tt778	878
779	tt779	879
780	tt780	880
781	tt781	881
782	tt782	882
783	tt783	883
784	tt784	884
785	tt785	885
786	tt786	886
787	tt787	887
788	tt788	888
789	tt789	889
790	tt790	890
791	tt791	891
792	tt792	892
793	tt793	893
794	tt794	894
795	tt795	895
796	tt796	896
797	tt797	897
798	tt798	898
799	tt799	899
800	tt800	900
801	tt801	901
802	tt802	902
803	tt803	903
804	tt804	904
805	tt805	905
806	tt806	906
807	tt807	907
808	tt808	908
809	tt809	909
810	tt810	910
811	tt811	911
812	tt812	912
813	tt813	913
814	tt814	914
815	tt815	915
816	tt816	916
817	tt817	917
818	tt818	918
819	tt819	919
820	tt820	920
821	tt821	921
822	tt822	922
823	tt823	923
824	tt824	924
825	tt825	925
826	tt826	926
827	tt827	927
828	tt828	928
829	tt829	929
830	tt830	930
831	tt831	931
832	tt832	932
833	tt833	933
834	tt834	934
835	tt835	935
836	tt836	936
837	tt837	937
838	tt838	938
839	tt839	939
840	tt840	940
841	tt841	941
842	tt842	942
843	tt843	943
844	tt844	944
845	tt845	945
846	tt846	946
847	tt847	947
848	tt848	948
849	tt849	949
850	tt850	950
851	tt851	951
852	tt852	952
853	tt853	953
854	tt854	954
855	tt855	955
856	tt856	956
857	tt857	957
858	tt858	958
859	tt859	959
860	tt860	960
861	tt861	961
862	tt862	962
863	tt863	963
864	tt864	964
865	tt865	965
866	tt866	966
867	tt867	967
868	tt868	968
869	tt869	969
870	tt870	970
871	tt871	971
872	tt872	972
873	tt873	973
874	tt874	974
875	tt875	975
876	tt876	976
877	tt877	977
878	tt878	978
879	tt879	979
880	tt880	980
881	tt881	981
882	tt882	982
883	tt883	983
884	tt884	984
885	tt885	985
886	tt886	986
887	tt887	987
888	tt888	988
889	tt889	989
890	tt890	990
891	tt891	991
892	tt892	992
893	tt893	993
894	tt894	994
895	tt895	995
896	tt896	996
897	tt897	997
898	tt898	998
899	tt899	999
900	tt900	1000
901	tt901	1001
902	tt902	1002
903	tt903	1003
904	tt904	1004
905	tt905	1005
906	tt906	1006
907	tt907	1007
908	tt908	1008
909	tt909	1009
910	tt910	1010
911	tt911	1011
912	tt912	1012
913	tt913	1013
914	tt914	1014
915	tt915	1015
916	tt916	1016
917	tt917	1017
918	tt918	1018
919	tt919	1019
920	tt920	1020
921	tt921	1021
922	tt922	1022
923	tt923	1023
924	tt924	1024
925	tt925	1025
926	tt926	1026
927	tt927	1027
928	tt928	1028
929	tt929	1029
930	tt930	1030
931	tt931	1031
932	tt932	1032
933	tt933	1033
934	tt934	1034
935	tt935	1035
936	tt936	1036
937	tt937	1037
938	tt938	1038
939	tt939	1039
940	tt940	1040
941	tt941	1041
942	tt942	1042
943	tt943	1043
944	tt944	1044
945	tt945	1045
946	tt946	1046
947	tt947	1047
948	tt948	1048
949	tt949	1049
950	tt950	1050
951	tt951	1051
952	tt952	1052
953	tt953	1053
954	tt954	1054
955	tt955	1055
956	tt956	1056
957	tt957	1057
958	tt958	1058
959	tt959	1059
960	tt960	1060
961	tt961	1061
962	tt962	1062
963	tt963	1063
964	tt964	1064
965	tt965	1065
966	tt966	1066
967	tt967	1067
968	tt968	1068
969	tt969	1069
970	tt970	1070
971	tt971	1071
972	tt972	1072
973	tt973	1073
974	tt974	1074
975	tt975	1075
976	tt976	1076
977	tt977	1077
978	tt978	1078
979	tt979	1079
980	tt980	1080
981	tt981	1081
982	tt982	1082
983	tt983	1083
984	tt984	1084
985	tt985	1085
986	tt986	1086
987	tt987	1087
988	tt988	1088
989	tt989	1089
990	tt990	1090
991	tt991	1091
992	tt992	1092
993	tt993	1093
994	tt994	1094
995	tt995	1095
996	tt996	1096
997	tt997	1097
998	tt998	1098
999	tt999	1099
1000	tt1000	1100
\.


--
-- Data for Name: task_audit; Type: TABLE DATA; Schema: myschema; Owner: springstudent
--

COPY myschema.task_audit (log_id, task_id, entry_date, operation) FROM stdin;
1	8	2024-10-21	INSERT
2	9	2024-10-21	INSERT
3	10	2024-10-21	INSERT
4	12	2024-10-23	INSERT
40	1	2024-11-06	INSERT
41	1	2024-11-06	INSERT
42	1	2024-11-06	INSERT
\.


--
-- Data for Name: tasks; Type: TABLE DATA; Schema: myschema; Owner: springstudent
--

COPY myschema.tasks (task_id, task_name, task_desc, task_type, parent) FROM stdin;
4	Task4	The fourth task	TX	3
8	Task8	The eighth task	\N	\N
9	Task9	The ninth task	T9	8
10	Task10	The tenth task	T10	8
1	The first task!	The first task	\N	\N
3	Task3	The third task	TX	1
\.


--
-- Data for Name: tasks_archive; Type: TABLE DATA; Schema: myschema; Owner: springstudent
--

COPY myschema.tasks_archive (task_id, task_name, task_desc, task_type, parent) FROM stdin;
5	Task5	The fifth task	T3	\N
7	Task7	The seventh task	T3	5
6	Task6	The sixth task	T3	5
\.


--
-- Data for Name: authorities; Type: TABLE DATA; Schema: public; Owner: springstudent
--

COPY public.authorities (username, authority) FROM stdin;
john	ROLE_STUDENT
amy	ROLE_TEACHER
prince	ROLE_TEACHER
prince	ROLE_ADMIN
\.


--
-- Data for Name: counter; Type: TABLE DATA; Schema: public; Owner: springstudent
--

COPY public.counter (count) FROM stdin;
3
\.


--
-- Data for Name: custom_authorities; Type: TABLE DATA; Schema: public; Owner: springstudent
--

COPY public.custom_authorities (userid, role) FROM stdin;
john	STUDENT
amy	TEACHER
prince	TEACHER
prince	ADMIN
\.


--
-- Data for Name: custom_space_table; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.custom_space_table (id, name) FROM stdin;
3	Jack
2	Bob
1	Alice
\.


--
-- Data for Name: custom_users; Type: TABLE DATA; Schema: public; Owner: springstudent
--

COPY public.custom_users (userid, pwd, age, enabled) FROM stdin;
john	{bcrypt}$2a$12$hrEaU.DlOHFFz./tvhSKqutvEYz1E0aJRfQ71DSQMpW2unEDoegZi	24	Y
amy	{bcrypt}$2a$12$/I3plg0ELFDOAqCoo.NFX.ZTtyGUTQS.tBZk0IywYu6WzBQCcYt6C	25	Y
prince	{bcrypt}$2a$12$QJszp0OHuMlE2fNjREC6fOCvhtnrd6tuJLPUBLG68qE0oNXwQKT1y	31	Y
\.


--
-- Data for Name: greeting; Type: TABLE DATA; Schema: public; Owner: springstudent
--

COPY public.greeting (id, message, student_id) FROM stdin;
2	Hello World!	4
3	Hello Again 1	4
4	Hello Again 2	4
5	Hello-world	5
\.


--
-- Data for Name: student; Type: TABLE DATA; Schema: public; Owner: springstudent
--

COPY public.student (id, first_name, last_name, email) FROM stdin;
4	Iron2	Scar	ironscar@gmail.com
5	Mia3	Jigolo3	mogolo3@yahoo.com
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: springstudent
--

COPY public.users (username, password, enabled) FROM stdin;
john	{bcrypt}$2a$12$hrEaU.DlOHFFz./tvhSKqutvEYz1E0aJRfQ71DSQMpW2unEDoegZi	1
amy	{bcrypt}$2a$12$/I3plg0ELFDOAqCoo.NFX.ZTtyGUTQS.tBZk0IywYu6WzBQCcYt6C	1
prince	{bcrypt}$2a$12$QJszp0OHuMlE2fNjREC6fOCvhtnrd6tuJLPUBLG68qE0oNXwQKT1y	1
\.


--
-- Name: task_audit_log_id_seq; Type: SEQUENCE SET; Schema: myschema; Owner: springstudent
--

SELECT pg_catalog.setval('myschema.task_audit_log_id_seq', 45, true);


--
-- Name: greeting_id_seq; Type: SEQUENCE SET; Schema: public; Owner: springstudent
--

SELECT pg_catalog.setval('public.greeting_id_seq', 5, true);


--
-- Name: student_id_seq; Type: SEQUENCE SET; Schema: public; Owner: springstudent
--

SELECT pg_catalog.setval('public.student_id_seq', 7, true);


--
-- Name: task_audit task_audit_pkey; Type: CONSTRAINT; Schema: myschema; Owner: springstudent
--

ALTER TABLE ONLY myschema.task_audit
    ADD CONSTRAINT task_audit_pkey PRIMARY KEY (log_id);


--
-- Name: tasks_archive tasks_archive_pkey; Type: CONSTRAINT; Schema: myschema; Owner: springstudent
--

ALTER TABLE ONLY myschema.tasks_archive
    ADD CONSTRAINT tasks_archive_pkey PRIMARY KEY (task_id);


--
-- Name: tasks tasks_sort_key; Type: CONSTRAINT; Schema: myschema; Owner: springstudent
--

ALTER TABLE ONLY myschema.tasks
    ADD CONSTRAINT tasks_sort_key UNIQUE (task_id) DEFERRABLE INITIALLY DEFERRED;


--
-- Name: authorities authorities_username_authority_key; Type: CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.authorities
    ADD CONSTRAINT authorities_username_authority_key UNIQUE (username, authority);


--
-- Name: custom_authorities custom_authorities_userid_role_key; Type: CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.custom_authorities
    ADD CONSTRAINT custom_authorities_userid_role_key UNIQUE (userid, role);


--
-- Name: custom_users custom_users_pkey; Type: CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.custom_users
    ADD CONSTRAINT custom_users_pkey PRIMARY KEY (userid);


--
-- Name: greeting greeting_pkey; Type: CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.greeting
    ADD CONSTRAINT greeting_pkey PRIMARY KEY (id);


--
-- Name: student student_pkey; Type: CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (username);


--
-- Name: myschema_index3; Type: INDEX; Schema: myschema; Owner: springstudent
--

CREATE INDEX myschema_index3 ON myschema.index_trial_tasks USING btree (lower((task_title)::text));


--
-- Name: authorities authorities_username_fkey; Type: FK CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.authorities
    ADD CONSTRAINT authorities_username_fkey FOREIGN KEY (username) REFERENCES public.users(username);


--
-- Name: custom_authorities custom_authorities_userid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.custom_authorities
    ADD CONSTRAINT custom_authorities_userid_fkey FOREIGN KEY (userid) REFERENCES public.custom_users(userid);


--
-- Name: greeting greeting_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: springstudent
--

ALTER TABLE ONLY public.greeting
    ADD CONSTRAINT greeting_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.student(id);


--
-- Name: SCHEMA myschema; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA myschema TO springstudent;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO springstudent;


--
-- PostgreSQL database dump complete
--

