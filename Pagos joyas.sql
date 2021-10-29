---select * from agencias where cnomage like '%san carlos%' 30,40,33,6
BEGIN TRAN

/*
 - Contrato 1238759
 - Contrato 1234713
 - Contrato1230464
 - Contrato1230464
*/

declare @dfecha as date='12/10/2021'
declare @ncodage as int=##
--DECLARE @NUMTRANS AS INT=2410543

declare @nnrotrans as int, @NCODPIGNORATICIO AS INT
declare @DT int,@nTasaInt money, @nTasaGA money,@nSaldoK money
declare @nCapital money, @nInteres money
declare @nSaldoAntesOperacion money
declare @nCodTarifario int, @nTasaCustodia money,@nTasaOtrosG money

--SELECT @NCODPIGNORATICIO =NCODPIGNORATICIO FROM PignoraticioKardex where nNroTrans=@NUMTRANS

declare  Cur_Operaciones cursor

for
select nnrotrans, nCodPignoraticio from PignoraticioKardex
where nAgencia=@ncodage and cast(dfecha as date)=@dfecha and nCorComp!=0
--AND nNroTrans=@NUMTRANS

--DELETE FROM PignoraticioTransac WHERE nNroTrans=@NUMTRANS


OPEN Cur_Operaciones  
  
FETCH NEXT FROM Cur_Operaciones   
INTO @nnrotrans , @NCODPIGNORATICIO
  
WHILE @@FETCH_STATUS = 0  
BEGIN  
   print @nnrotrans
     
	 
select @nSaldoAntesOperacion=nMontonuevosaldo  from PignoraticioKardex K 
where K.nCodPignoraticio = @NCODPIGNORATICIO and
nTipoOperacion in(1307,1306,1308,1304,1305) and bExtorno =0
and cast(dFecha as date)= (select max(cast(dFecha as date))from PignoraticioKardex K1 where nTipoOperacion in(1307,1306,1308,1304,1305) and bExtorno =0
and nCodPignoraticio = K.nCodPignoraticio and cast(dFecha as date)<'20211012')

set @nSaldoAntesOperacion= isnull(@nSaldoAntesOperacion,0)

--select @nSaldoAntesOperacion nSaldoAntesOperacion



	select @nCapital= @nSaldoAntesOperacion  - isnull(K.nMontonuevosaldo,0) 
		, @nTasaCustodia = case when isnull(P.nTasaCustodia,0)>0 then P.nTasaCustodia else PT.nTasaCustodia end,
		@nTasaOtrosG = case when isnull(P.nTasaOtrosGasAdm,0)>0 then P.nTasaOtrosGasAdm else PT.nTasaOtrosGasAdm end
	FROM Pignoraticio P inner join PignoraticioKardex K on P.nCodPignoraticio = K.nCodPignoraticio 
	left join PignoraticioTarifario PT on PT.ncodPignoraticioTarifario = P.nCodTarifario
	where K.nNroTrans =@nNroTrans 

	-- select top 1*from PignoraticioTarifario

	INSERT INTO PignoraticioTransac	
	SELECT K.nnrotrans,P.ncodpignoraticio, K.nitem ,2, K.ntipooperacion, 
	round(K.nDiasTranscurridosAlPago *nTasaInteresPuro/100.00*@nSaldoAntesOperacion/(30.00),2), K.nEstado,K.bExtorno,K.dFecha     --@nTasaGA = nTasaGA  
	FROM Pignoraticio P inner join PignoraticioKardex K on P.nCodPignoraticio = K.nCodPignoraticio 
	where K.nNroTrans =@nNroTrans 
	UNION
	SELECT K.nnrotrans,P.ncodpignoraticio, K.nitem ,9, K.ntipooperacion, 
	round(K.nDiasTranscurridosAlPago *@nTasaCustodia/100.00*@nSaldoAntesOperacion/(30.00),2), K.nEstado,K.bExtorno,K.dFecha     --@nTasaGA = nTasaGA  
	FROM Pignoraticio P inner join PignoraticioKardex K on P.nCodPignoraticio = K.nCodPignoraticio 
	where K.nNroTrans =@nNroTrans 
	UNION
	SELECT K.nnrotrans,P.ncodpignoraticio, K.nitem ,26, K.ntipooperacion, 
	round(K.nDiasTranscurridosAlPago *@nTasaOtrosG/100.00*@nSaldoAntesOperacion/(30.00),2), K.nEstado,K.bExtorno,K.dFecha     --@nTasaGA = nTasaGA  
	FROM Pignoraticio P inner join PignoraticioKardex K on P.nCodPignoraticio = K.nCodPignoraticio 
	where K.nNroTrans =@nNroTrans 
-----------------------------
	UNION
	SELECT K.nnrotrans,P.ncodpignoraticio, K.nitem ,3, K.ntipooperacion, 
	--round(K.nDiasTranscurridosAlPago *@nTasaOtrosG/100.00*@nSaldoAntesOperacion/(30.00),2), 
	round((@nSaldoAntesOperacion * (P.nTasaInteresMoratorio / 100)/30)*
	(case when K.nDiasTranscurridosAlPago-30>15 then K.nDiasTranscurridosAlPago-30 else 0 end),2),  
	K.nEstado,K.bExtorno,K.dFecha     --@nTasaGA = nTasaGA  
	FROM Pignoraticio P inner join PignoraticioKardex K on P.nCodPignoraticio = K.nCodPignoraticio 
	where K.nNroTrans =@nNroTrans 
-----------------------------
	UNION
	SELECT K.nnrotrans,P.ncodpignoraticio, K.nitem ,5, K.ntipooperacion, 
	K.nMonto -@nCapital- (round(K.nDiasTranscurridosAlPago *nTasaInteresPuro/100.00*@nSaldoAntesOperacion/(30.00),2)
	+round(K.nDiasTranscurridosAlPago *@nTasaCustodia/100.00*@nSaldoAntesOperacion/(30.00),2)
	+round(K.nDiasTranscurridosAlPago *@nTasaOtrosG/100.00*@nSaldoAntesOperacion/(30.00),2)
	+ round((@nSaldoAntesOperacion * (P.nTasaInteresMoratorio / 100)/30)*
	(case when K.nDiasTranscurridosAlPago-30>15 then K.nDiasTranscurridosAlPago-30 else 0 end),2)
	), 
	K.nEstado,K.bExtorno,K.dFecha     --@nTasaGA = nTasaGA  	
	FROM Pignoraticio P inner join PignoraticioKardex K on P.nCodPignoraticio = K.nCodPignoraticio 
	where K.nNroTrans =@nNroTrans 
	UNION
	SELECT K.nnrotrans,P.ncodpignoraticio, K.nitem ,1, K.ntipooperacion, 
	@nCapital ,K.nEstado,K.bExtorno,K.dFecha     --@nTasaGA = nTasaGA  	
	FROM Pignoraticio P inner join PignoraticioKardex K on P.nCodPignoraticio = K.nCodPignoraticio 
	where K.nNroTrans =@nNroTrans and @nCapital>0




    FETCH NEXT FROM Cur_Operaciones   
    INTO @nnrotrans,@NCODPIGNORATICIO
END   


CLOSE Cur_Operaciones;  
DEALLOCATE Cur_Operaciones;  
-- rollback tran
COMMIT TRAN