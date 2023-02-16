USE [Cnr_VolvoService]
GO
/****** Object:  StoredProcedure [dbo].[Kakao_manage]    Script Date: 2023-02-14 오전 9:41:47 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =======================================================================================================================================
-- Author:		컴나래<오서희>
-- Create date: 2022-07-14
-- Description:	Kakao_manage
-- Comment	  : 카카오 알림톡 발송 예외처리 및 정보 

-- Result	  : 시스템 오류 ( -1 ) , 사용자 데이터 확인오류 ( -100 ) >> -100 의 경우 msg 구문을 사용자에게 바로 보여준다.

-- ========================================================================================================================================
--EXEC dbo.kakao_manage @send_client = 'DMS', @dlr_cd = 'HMSS', @pro_fl = 'TEST', @split_data = 'RO', @data_ro = 'BHMSS22070016', @data_tel = '01094706087', @kind_cd = 'BK', @input_user_id = 'mhj', @tel_change_flag = ''

ALTER PROCEDURE [dbo].[Kakao_manage]			
	@send_client		varchar(10)		= ''				-- 프로시저 호출 가능 프로그램 ( DMS / S_APP [서비스앱] / IMS / HEY_APP [헤이볼보앱] )
	,@dlr_cd			varchar(10)		= ''				-- 서비스센터 코드
	,@pro_fl			varchar(10)     = 'TEST'			-- 해당 항목에 값이 없을경우 무조건 테스트로. ( TEST / PRO )
	,@split_data		varchar(10)		= ''				-- Cursor 주 데이터 ( RO / TEL )
	,@data_ro			nvarchar(max)	= ''				-- R/O ( EX. RIRGA22070185,RIRGA22070179,RIRGA22070178)
	,@data_tel			nvarchar(max)	= ''				-- 전화번호 ( R/O 처럼 [,] 로 휴대폰번호가 연결되어 들어온다. )
	,@kind_cd			varchar(10)		= ''				-- 카카오 메세지 구분 코드.
	,@input_user_id		varchar(20)		= ''				-- 사용자 ID
	,@tel_change_flag	varchar(10)		= 'Y'				-- 고객전화번호 변경여부
AS
SET NOCOUNT ON

-- Send Value
DECLARE @sed_send_fl varchar(10),			@sed_send_client varchar(10),			@sed_dlr_cd varchar(10),		@sed_pro_fl varchar(10),		@sed_data_ro nvarchar(max)
DECLARE	@sed_kind_cd varchar(10),			@sed_input_user_id varchar(20),			@sed_data_tel nvarchar(max),	@sed_split_data varchar(10),	@sed_tel_change_flag varchar(10);

-- Result Value
DECLARE @res_code int,						@res_msg varchar(max);

DECLARE @company varchar(10) = 'VCK',		@department varchar(10) = 'service',	@input_user_nm varchar(20),		@data_in_user varchar(100)
DECLARE @estimate_url varchar(100),			@invoice_url varchar(100),				@checklist_url varchar(100),	@client_id varchar(50),			@kakao_if_url varchar(200)
DECLARE @sender_no varchar(50),				@dlr_tel varchar(20),					@dlr_comp_no varchar(20),		@dlr_app_nm varchar(50),		@bk_map_url varchar(200)
DECLARE @ro_status_nm varchar(100),			@dlr_addr varchar(200),					@base_dt varchar(10)

/* 카카오 알림톡 템플릿 코드 */
DECLARE @temp_cnt int,						@temp_cd varchar(50),					@temp_flag varchar(1),			@temp_type varchar(10),			@temp_msg varchar(5000)
DECLARE	@temp_estimate char(1),				@temp_invoice char(1),					@temp_checklist char(1),		@temp_btn_url_01 varchar(200),	@temp_btn_url_02 varchar(200)
DECLARE @temp_btn_url_03 varchar(200),		@temp_btn_url_04 varchar(200),			@temp_btn_url_05 varchar(200),	@temp_phone_msg varchar(5000),	@temp_item_header varchar(500)
DECLARE @temp_item_data varchar(5000);

/* 카카오 알림톡 전달 데이터값 */
DECLARE @k_msg_key varchar(100),			@cur_data nvarchar(max),				@k_msg_data varchar(50)
DECLARE @k_print_est_url varchar(500) = '',	@k_print_invoice_url varchar(500) = '',	@k_print_check_url varchar(500) = ''
DECLARE @k_print_est_key varchar(100) = '', @k_print_invoice_key varchar(100) = '', @k_print_check_key varchar(100) = ''
DECLARE @k_print_rtn varchar(20),			@k_msg_text_01 varchar(500),			@k_msg_text_02 varchar(500) = '',	@k_cust_tel varchar(20),	@k_cust_tel_change varchar(20),		@emp_dealer_ship_cd varchar(10)
DECLARE	@k_cust_cd int,						@k_booking_dt varchar(20),				@k_booking_time varchar(20),	@k_carno varchar(20),			@k_vin varchar(50)
DECLARE	@k_brand varchar(2),				@k_reg_userid varchar(20),				@k_wer_dt varchar(20),			@k_out_dt varchar(20),			@k_out_fl varchar(10)
DECLARE @k_pre_out_dt varchar(20),			@k_msg_title varchar(100),				@k_msg_phone varchar(5000),		@k_btn_url_01 varchar(1000) = '',@k_btn_url_02 varchar(1000) = ''
DECLARE @k_btn_url_03 varchar(1000)='',		@k_btn_url_04 varchar(1000) = '',		@k_btn_url_05 varchar(1000)='',	@k_json_data varchar(max),		@k_pre_out_time varchar(10)
DECLARE @k_kko_msg varchar(5000),			@k_msg_type varchar(10),				@k_result_insert varchar(max),	@k_result_table varchar(max)
DECLARE @k_item_data varchar(5000)='';

DECLARE @Print_key Table (		return_fl varchar(50), 
								return_key varchar(100), 
								Err_num varchar(100), 
								Err_sev varchar(100), 
								Err_sta varchar(100), 
								Err_pro varchar(100), 
								Err_lin varchar(100), 
								Err_msg varchar(100)
							)
DECLARE @temp_json Table (		json_temp varchar(max)	)
DECLARE @int int

SET @sed_send_client	= @send_client
SET @sed_dlr_cd			= @dlr_cd
SET @sed_pro_fl			= @pro_fl
SET @sed_split_data		= @split_data
SET @sed_data_ro		= @data_ro
SET @sed_data_tel		= @data_tel
SET @sed_kind_cd		= @kind_cd
SET @sed_input_user_id	= @input_user_id
SET @sed_tel_change_flag = @tel_change_flag

IF TRIM(@sed_tel_change_flag) <> 'N'
BEGIN SET @sed_tel_change_flag = 'Y'
END

/* 고정값 관리 */
IF @sed_pro_fl = 'TEST'
BEGIN
	SET @client_id		= 'R000000023_003'
	SET @kakao_if_url	= 'https://messageapi-test.comnarae.com:8888/kakaoagent/send_agent'
	SET @estimate_url	= 'https://vckcustomer-test.comnarae.com/service/print02.asp?ro_flag='
	SET @invoice_url	= 'https://vckcustomer-test.comnarae.com/service/print01.asp?ro_flag='
	SET @checklist_url	= 'https://vckcustomer-test.comnarae.com/service/print06.asp?ro_flag='
	SET @sender_no		= '0513297777'
END
ELSE
BEGIN
	SET @client_id		= 'R000000015_002'
	SET @kakao_if_url	= 'https://messageapi.comnarae.com:8080/kakaoagent/send_agent'
	SET @estimate_url	= 'https://vckcustomer.comnarae.com/service/print02.asp?ro_flag='
	SET @invoice_url	= 'https://vckcustomer.comnarae.com/service/print01.asp?ro_flag='
	SET @checklist_url	= 'https://vckcustomer.comnarae.com/service/print06.asp?ro_flag='
	SET @sender_no		= '15881777'
END

--예약안내 및 리마인드 알림톡 시 URL 정보 가져오기 
SELECT @bk_map_url = service_map_url
  FROM Cnr_VolvoSales.dbo.dealership  WITH(NOLOCK)
 WHERE dealership_code = (SELECT dealership_code FROM Dealer_info WITH(NoLock) WHERE dlr_cd = @sed_dlr_cd)

-- url 정보없을 경우 VCK url 로 대체
IF @bk_map_url = '' OR @bk_map_url Is Null
BEGIN
	SET @bk_map_url = 'http://www.volvocars.com/kr/own/owner-info/service-center'
END

-- 카카오 알림톡 호출 사용자 이름 체크.
SELECT @input_user_nm = IsNull(emp_nm,'')
  FROM Employee WITH(NoLock)
 WHERE emp_id = @sed_input_user_id

 IF @input_user_nm Is NULL
BEGIN
	SET @input_user_nm = ''
END

SET @data_in_user = @sed_input_user_id + ' ' + @input_user_nm

-- KAKAO_RESULT 생성을 API 로 넘기기 위해 INSERT문을 프로시저에서 작성.
SET @k_result_table = 'INSERT INTO kakao_result (k_msg_key, dlr_cd, ro_no, carno, cust_tel, message_kind, kko_template_cd, kko_template_type, Estimate_key, invoice_key, checklist_key, data_in_dt, data_in_user, send_fl) 
						VALUES ( '

BEGIN TRY

	/* Send 값 확인 예외처리 */
	IF @sed_send_fl = '' OR @sed_send_client = ''OR @sed_dlr_cd = '' OR @sed_kind_cd = '' 
	BEGIN
		SET @res_code = -1;		
		SET @res_msg = '프로시저 호출 오류. 전달 데이터값을 확인해주세요.'

		GOTO Error
	END
	IF @sed_send_client <> 'DMS' AND @sed_send_client <> 'S_APP' AND @sed_send_client <> 'IMS' AND @sed_send_client <> 'HEY_APP'
	BEGIN
		SET @res_code = -1;		
		SET @res_msg = 'send_client 값을 확인해주세요.'

		GOTO Error
	END
	
	-- 마스터 템플릿 코드 정보 확인.
	SELECT @temp_cnt = COUNT(0),				@temp_cd = temp_cd,					@temp_flag = ro_flag,				@temp_type = temp_type,				@temp_msg = temp_msg,
		   @temp_estimate = Estimate_yn,		@temp_invoice = invoice_yn,			@temp_checklist = checklist_yn,		@temp_btn_url_01 = kko_btn_link1,	@temp_btn_url_02 = kko_btn_link2,
		   @temp_btn_url_03 = kko_btn_link3,	@temp_btn_url_04 = kko_btn_link4,	@temp_btn_url_05 = kko_btn_link5,	@temp_phone_msg = phone_msg,		@temp_item_header = HEADER,
		   @temp_item_data = ITEM
	  FROM kakao_template_info WITH(NoLock)
	 WHERE message_kind = @sed_kind_cd
	   AND client_id = @client_id
	   AND use_dt_st <= getdate()
	   AND use_dt_et >= getdate()
	GROUP BY temp_cd, ro_flag, temp_type, temp_msg, Estimate_yn, invoice_yn, checklist_yn, kko_btn_link1, kko_btn_link2, kko_btn_link3, kko_btn_link4, kko_btn_link5, phone_msg,
			header, item

	IF @temp_cnt < 1
	BEGIN		
		SET @res_code = -1;		
		SET @res_msg = '템플릿 코드가 확인되지 않습니다.'

		GOTO Error
	END
	ELSE IF @temp_cnt > 1
	BEGIN
		SET @res_code = -1;		
		SET @res_msg = '템플릿 코드가 여러 건으로 확인됩니다. 데이터 확인이 필요합니다.'

		GOTO Error
	END
	IF @temp_cd = '' OR @temp_cd Is Null OR @temp_flag = '' OR @temp_flag Is Null OR @temp_type = '' OR @temp_type Is Null OR @temp_msg = '' OR @temp_msg Is Null
	BEGIN
		SET @res_code = -1;		
		SET @res_msg = '템플릿 코드 마스터 정보 확인이 필요합니다.'

		GOTO Error
	END

	-- 서비스센터 필수 정보 확인
	SELECT @dlr_tel = dbo.replaceCustomerHP(tel,'Y'), @dlr_comp_no = comp_no, @dlr_app_nm = App_Dlr_nm, @dlr_addr = Addr_Tail --+ Addr_Input //변수 부분 최대글자 23자 까지 제한되어 있음
	  FROM Dealer_info WITH(NoLock)
	 WHERE dlr_cd = @sed_dlr_cd

	IF @dlr_tel = '' OR @dlr_tel Is Null OR @dlr_comp_no = '' OR @dlr_comp_no Is Null OR @dlr_app_nm = '' OR @dlr_app_nm Is Null OR @dlr_addr = '' OR @dlr_addr Is Null
	BEGIN
		SET @res_code = -100;		
		SET @res_msg = '서비스센터 정보를 확인바랍니다. ( 전화번호, 사업자번호, 딜러명 )'

		GOTO Error
	END

	-- CURSOR 를 어떤 데이터 기준으로 처리할 건지 정의.
	IF @split_data = 'RO'
	BEGIN
		SET @cur_data = @sed_data_ro
	END 
	ELSE
	BEGIN
		SET @cur_data = @sed_data_tel
	END

	IF @cur_data = '' OR @cur_data Is Null 
	BEGIN
		SET @res_code = -1;		
		SET @res_msg = '발송 데이터를 확인해주세요 ( R/O OR TEL )'

		GOTO Error
	END

	-- 넘어온 R/O 갯수만큼 Json 생성처리.
	DECLARE CUR_KAKAO_JSON CURSOR FOR
		SELECT return_data
		  FROM dbo.Tb_String_Split(@cur_data, ',')
	OPEN CUR_KAKAO_JSON
		FETCH NEXT FROM CUR_KAKAO_JSON INTO @k_msg_data
	WHILE (@@FETCH_STATUS = 0)
		BEGIN
						
			-- temp_flag 가 B, E, R 일 땐 R/O 가 필수정보여야 하며, 데이터가 맞지 않을 경우, 테이블 데이터 검색을 할 수 없음으로 오류로 확인한다.
			IF @temp_flag = 'B' OR @temp_flag = 'E' OR @temp_flag = 'R' 
			BEGIN
				IF LEFT(@k_msg_data,1) <> @temp_flag
				BEGIN					
					SET @res_code = -1;		
					SET @res_msg = '발송 데이터와 카카오 구분자가 매칭되지 않습니다.'
					BREAK;
				END
			END

			-- 조회 데이터 정리
			IF @temp_flag = 'B'
			BEGIN
				SELECT	@k_cust_tel		= IsNull(cust_tel,''),				@k_cust_cd		= IsNull(cust_cd,0),		
						@k_booking_dt	= IsNull(CONCAT(LEFT(bk_reg_dt,4), '/', SUBSTRING(bk_reg_dt,5,2),'/', SUBSTRING(bk_reg_dt,7,2))  + ' (' + LEFT(DATENAME(WEEKDAY, dbo.convertDate10(bk_reg_dt)), 1) + ')',''),		
						@k_booking_time = IsNull(bk_reg_dt_st,''),			@k_carno		= IsNull(carno,''),			@k_vin = IsNull(vin,''),				
						@k_brand		= IsNull(brand_cd,'VO'),			@k_reg_userid	= IsNull(reg_user,''),		@base_dt = reg_dt
				  FROM Booking_main WITH(NoLock)
				 WHERE dlr_cd = @sed_dlr_cd
				   AND ro_no = @k_msg_data
			END

			IF @temp_flag = 'E'
			BEGIN
				SELECT	@k_cust_tel		= IsNull(cust_tel,''),				@k_cust_cd		= IsNull(cust_cd,0),		
						@k_carno		= IsNull(carno,''),					@k_vin = IsNull(vin,''),				
						@k_brand		= IsNull(brand_cd,'VO'),			@k_reg_userid	= IsNull(reg_user,''),		@base_dt = reg_dt
				  FROM Estimate_main WITH(NoLock)
				 WHERE dlr_cd = @sed_dlr_cd
				   AND ro_no = @k_msg_data
			END

			IF @temp_flag = 'R'
			BEGIN
				SELECT	@k_cust_tel		= IsNull(cust_tel,''),				@k_cust_cd		= IsNull(cust_cd,0),		
						@k_carno		= IsNull(carno,''),					@k_vin = IsNull(vin,''),				
						@k_brand		= IsNull(brand_cd,'VO'),			@k_reg_userid	= IsNull(reg_user,''),
						@k_out_fl		= IsNull(out_fl, ''),
						@k_wer_dt = CONCAT(LEFT(wer_dt,4), '/', SUBSTRING(wer_dt,5,2),'/', SUBSTRING(wer_dt,7,2))  + ' (' + LEFT(DATENAME(WEEKDAY, dbo.convertDate10(wer_dt)), 1) + ')',
						@k_out_dt = CONCAT(LEFT(out_dt,4), '/', SUBSTRING(out_dt,5,2),'/', SUBSTRING(out_dt,7,2))  + ' (' + LEFT(DATENAME(WEEKDAY, dbo.convertDate10(out_dt)), 1) + ')',
						@k_pre_out_dt = CONCAT(LEFT(pre_out_dt,4), '/', SUBSTRING(pre_out_dt,5,2),'/', SUBSTRING(pre_out_dt,7,2))  + ' (' + LEFT(DATENAME(WEEKDAY, dbo.convertDate10(pre_out_dt)), 1) + ')',
						@k_pre_out_time = Substring(pre_out_dt, 9, 2) + ':' + Right(pre_out_dt, 2),						@base_dt = wer_dt
				  FROM Repair_main WITH(NoLock)
				 WHERE dlr_cd = @sed_dlr_cd
				   AND ro_no = @k_msg_data
			END

			-- 정비견적서, 명세서, 정기점검표 Key 데이터 생성.
			IF (@temp_estimate = 'Y' OR @temp_checklist = 'Y' OR @temp_invoice = 'Y') AND @split_data = 'RO'
			BEGIN

				-- 정비견적서 자료 생성
				IF @temp_estimate = 'Y'
				BEGIN
				
					IF @base_dt < '20221114'
					BEGIN
						INSERT INTO @Print_key
						EXEC [dbo].[DMS_printEstimate] @dlr_cd = @sed_dlr_cd, @ro_no = @k_msg_data, @mgr_program = 'DMS_K', @return_type = 'KAKAO', @data_in_user = @data_in_user
						SELECT @k_print_rtn = return_fl, @k_print_est_url = @estimate_url + return_key + '&send_fl=CUS', @k_print_est_key = return_key
						  FROM @Print_key
					END
					ELSE
					BEGIN
						INSERT INTO @Print_key
						EXEC [dbo].[DMS_PrintEstimateRepair_Invoice] @dlr_cd = @sed_dlr_cd, @ro_no = @k_msg_data, @mgr_program = 'DMS_K', @print_type = 'E', @return_type = 'KAKAO', @data_in_user = @data_in_user
						SELECT @k_print_rtn = return_fl, @k_print_est_url = @estimate_url + return_key + '&send_fl=CUS', @k_print_est_key = return_key
						  FROM @Print_key
					END

					IF @k_print_rtn <> 'TRUE'
					BEGIN				
						SET @res_code = -1;		
						SET @res_msg = '정비견적서 자료 생성 중에 오류가 발생하였습니다.' 
						BREAK;
					END

					DELETE FROM @Print_key
				END

				-- 정비명세서 자료 생성
				IF @temp_invoice = 'Y'
				BEGIN
					IF @base_dt < '20221114'
					BEGIN
						INSERT INTO @Print_key
						EXEC [dbo].[DMS_printRepairInvoice] @dlr_cd = @sed_dlr_cd, @ro_no = @k_msg_data, @mgr_program = 'DMS_K', @return_type = 'KAKAO', @data_in_user = @data_in_user
						SELECT @k_print_rtn = return_fl, @k_print_invoice_url = @invoice_url + return_key + '&send_fl=CUS', @k_print_invoice_key = return_key
						  FROM @Print_key
					END
					ELSE
					BEGIN
						INSERT INTO @Print_key
						EXEC [dbo].[DMS_PrintEstimateRepair_Invoice] @dlr_cd = @sed_dlr_cd, @ro_no = @k_msg_data, @mgr_program = 'DMS_K', @print_type = 'R', @return_type = 'KAKAO', @data_in_user = @data_in_user
						SELECT @k_print_rtn = return_fl, @k_print_invoice_url = @invoice_url + return_key + '&send_fl=CUS', @k_print_invoice_key = return_key
						  FROM @Print_key
					END

					IF @k_print_rtn <> 'TRUE'
					BEGIN				
						SET @res_code = -1;		
						SET @res_msg = '정비명세서 자료 생성 중에 오류가 발생하였습니다.' 
						BREAK;
					END

					DELETE FROM @Print_key
				END

				-- 정기점검표 자료 생성
				IF @temp_checklist = 'Y'
				BEGIN
					INSERT INTO @Print_key
					EXEC [dbo].[DMS_printFreeCheck] @dlr_cd = @sed_dlr_cd, @ro_no = @k_msg_data, @mgr_program = 'DMS_K', @return_type = 'KAKAO', @data_in_user = @data_in_user
					SELECT @k_print_rtn = return_fl, @k_print_check_url = @checklist_url + return_key + '&send_fl=CUS', @k_print_check_key = return_key
					  FROM @Print_key

					IF @k_print_rtn <> 'TRUE'
					BEGIN				
						SET @res_code = -1;		
						SET @res_msg = '정비명세서 자료 생성 중에 오류가 발생하였습니다.' 
						BREAK;
					END

					DELETE FROM @Print_key
				END
			END

			-- 카카오 메세지 Key 데이터 생성 ( 고객전화번호가 주 데이터일 경우, 뒤에 네자리만 사용 )
			SELECT @k_msg_key = CASE WHEN @split_data = 'RO' THEN @k_msg_data + '_' + @sed_kind_cd + '_' + REPLACE(REPLACE(REPLACE(CONVERT(varchar, getdate(), 20), '-', ''), ' ', ''), ':', '')
									 ELSE Right(@k_msg_data,4) + '_' + @sed_kind_cd + '_' + REPLACE(REPLACE(REPLACE(CONVERT(varchar, getdate(), 20), '-', ''), ' ', ''), ':', '') END

			IF @temp_flag = 'I'			-- IMS 카카오 알림톡 템플릿.
			BEGIN 
				SET @k_cust_tel = @k_msg_data
				SET @k_carno = 'Service_IMS'

				/* Comnare 관계자 ID 일 경우, 개인번호로 치환하여 발송 ( 고객에게 발송되지 않게 하기 위함 )
					IMS의 경우, 항시(테스트, 운영) 아래 담당자로 치환.
				*/
				IF Upper(@sed_input_user_id) = 'LYJ' BEGIN SET @k_cust_tel = '01023287741' END
				IF Upper(@sed_input_user_id) = 'JMH' BEGIN SET @k_cust_tel = '01093118683' END
				IF Upper(@sed_input_user_id) = 'KTH' BEGIN SET @k_cust_tel = '01025783729' END
				IF Upper(@sed_input_user_id) = 'JJY' BEGIN SET @k_cust_tel = '01075961123' END
				IF Upper(@sed_input_user_id) = 'OSH' BEGIN SET @k_cust_tel = '01022682722' END
				IF Upper(@sed_input_user_id) = 'LJE' BEGIN SET @k_cust_tel = '01028836420' END
				IF Upper(@sed_input_user_id) = 'MHJ' OR Upper(@sed_input_user_id) = 'COMNARAE' BEGIN SET @k_cust_tel = '01094706087' END
				IF Upper(@sed_input_user_id) = 'LDH' BEGIN SET @k_cust_tel = '01094419257' END
				IF Upper(@sed_input_user_id) = 'HYJ' BEGIN SET @k_cust_tel = '01099966462' END
				IF Upper(@sed_input_user_id) = 'JYJ' BEGIN SET @k_cust_tel = '01041088523' END
			END

			-- DMS에서 견적서, 명세서, 정기점검표 발송 시에는 작성된 전화번호로 발송하게끔 처리.
			IF @sed_send_client = 'DMS' AND (LEFT(@sed_kind_cd,2) = 'BS' OR LEFT(@sed_kind_cd,2) = 'ES' OR LEFT(@sed_kind_cd,2) = 'RS')
			BEGIN
				SET @k_cust_tel = @sed_data_tel
			END

			-- TEST 일 땐, 컴나래 사업자번호 치환하여 발송.
			IF @sed_pro_fl = 'TEST' 
			BEGIN
				SET @dlr_comp_no = '6068626699';

				SELECT @emp_dealer_ship_cd = dealership_code,	@k_cust_tel_change = hp 
				FROM Employee
				WHERE emp_id = @sed_input_user_id

				IF TRIM(@emp_dealer_ship_cd) = 'VCK'
				BEGIN 
					SET @k_cust_tel = @k_cust_tel_change
				END

				IF Trim(@emp_dealer_ship_cd) <> 'VCK' AND @sed_input_user_id NOT IN ('LYJ', 'JMH', 'KTH', 'JJY', 'OSH', 'LJE', 'MHJ', 'JYJ', 'HYJ') 
				BEGIN 
					SET @k_cust_tel = '01094706087'
				END 
				ELSE
					-- Comnare 관계자 ID 일 경우, 개인번호로 치환하여 발송 ( 고객에게 발송되지 않게 하기 위함 )
					IF Upper(@sed_input_user_id) = 'LYJ' BEGIN SET @k_cust_tel = '01023287741' END
					IF Upper(@sed_input_user_id) = 'JMH' BEGIN SET @k_cust_tel = '01093118683' END
					IF Upper(@sed_input_user_id) = 'KTH' BEGIN SET @k_cust_tel = '01025783729' END
					IF Upper(@sed_input_user_id) = 'JJY' BEGIN SET @k_cust_tel = '01075961123' END
					IF Upper(@sed_input_user_id) = 'OSH' BEGIN SET @k_cust_tel = '01022682722' END
					IF Upper(@sed_input_user_id) = 'LJE' BEGIN SET @k_cust_tel = '01028836420' END
					IF Upper(@sed_input_user_id) = 'MHJ' OR Upper(@sed_input_user_id) = 'COMNARAE' BEGIN SET @k_cust_tel = '01094706087' END
					IF Upper(@sed_input_user_id) = 'LDH' BEGIN SET @k_cust_tel = '01094419257' END
					IF Upper(@sed_input_user_id) = 'HYJ' BEGIN SET @k_cust_tel = '01099966462' END
					IF Upper(@sed_input_user_id) = 'JYJ' BEGIN SET @k_cust_tel = '01041088523' END
				END

			ELSE 

				SELECT @emp_dealer_ship_cd = dealership_code,	@k_cust_tel_change = hp 
				FROM Employee
				WHERE emp_id = @sed_input_user_id

				IF TRIM(@emp_dealer_ship_cd) = 'VCK'
				BEGIN 
					SET @k_cust_tel = @k_cust_tel_change
				END

				-- Comnare 관계자 ID 일 경우, 개인번호로 치환하여 발송 ( 고객에게 발송되지 않게 하기 위함 )
				IF Upper(@sed_input_user_id) = 'LYJ' BEGIN SET @k_cust_tel = '01023287741' END
				IF Upper(@sed_input_user_id) = 'JMH' BEGIN SET @k_cust_tel = '01093118683' END
				IF Upper(@sed_input_user_id) = 'KTH' BEGIN SET @k_cust_tel = '01025783729' END
				IF Upper(@sed_input_user_id) = 'JJY' BEGIN SET @k_cust_tel = '01075961123' END
				IF Upper(@sed_input_user_id) = 'OSH' BEGIN SET @k_cust_tel = '01022682722' END
				IF Upper(@sed_input_user_id) = 'LJE' BEGIN SET @k_cust_tel = '01028836420' END
				IF Upper(@sed_input_user_id) = 'MHJ' OR Upper(@sed_input_user_id) = 'COMNARAE' BEGIN SET @k_cust_tel = '01094706087' END
				IF Upper(@sed_input_user_id) = 'LDH' BEGIN SET @k_cust_tel = '01094419257' END
				IF Upper(@sed_input_user_id) = 'HYJ' BEGIN SET @k_cust_tel = '01099966462' END
				IF Upper(@sed_input_user_id) = 'JYJ' BEGIN SET @k_cust_tel = '01041088523' END

			
			IF @k_cust_tel = '' OR @k_cust_tel Is Null OR @k_carno = '' OR @k_carno Is Null 
			BEGIN			
				SET @res_code = -100;		
				SET @res_msg = '알림톡 발송제외(차량번호, 고객전화번호는 필수 확인사항입니다.)'
				BREAK;
			END
			
			-- 예약 관련 카카오 알림톡
			IF @sed_kind_cd = 'BK' OR @sed_kind_cd = 'RM' OR @sed_kind_cd = 'BC'
			BEGIN
				
				SET @k_msg_title = '예약안내'

				IF @sed_kind_cd = 'BC'
				BEGIN
					SET @k_msg_title = '예약취소'
			    END

				IF @sed_kind_cd = 'RM'
				BEGIN
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n예약된 내용을 재 안내 드립니다.' 
					SET @k_msg_text_02 = '예약 문의 및 변경/취소가 필요하신 경우, 서비스센터로 사전에 연락주시기 바랍니다.'
				END
				ELSE 
				BEGIN
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n서비스센터의 예약 정보를 안내 드립니다.'
					SET @k_msg_text_02 = '예약 문의 및 변경/취소가 필요하신 경우, 서비스센터로 사전에 연락주시기 바랍니다.'
				END

				-- Item List 형태로 변경됨에 따라 temp_cd 에 따른 로직 변경처리.
				IF Convert(varchar(8), getdate(), 112) >= '20220810'
				BEGIN
					SET @k_kko_msg = @temp_msg
					SELECT @k_msg_phone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_phone_msg, '#{예약일자}', @k_booking_dt), 
									'#{예약시간}', LEFT(@k_booking_time,2) + ':' +  RIGHT(@k_booking_time,2)), 
									'#{차량번호}', @k_carno), '#{예약센터}', @dlr_app_nm), '#{센터주소}', @dlr_addr), '#{예약문의}' , @dlr_tel)

					SELECT @k_item_data = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_item_data, '#{예약일자}', @k_booking_dt), 
									'#{예약시간}', LEFT(@k_booking_time,2) + ':' +  RIGHT(@k_booking_time,2)), 
									'#{차량번호}', @k_carno), '#{예약센터}', @dlr_app_nm), '#{센터주소}', @dlr_addr), '#{예약문의}' , @dlr_tel)
				END
				ELSE
				BEGIN

					SELECT @k_kko_msg = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_msg, '#{텍스트1}', @k_msg_text_01), '#{텍스트2}', @k_msg_text_02), 
											'#{예약일자}', @k_booking_dt), '#{예약시간}', LEFT(@k_booking_time,2) + ':' +  RIGHT(@k_booking_time,2)), 
									'#{차량번호}', @k_carno), '#{예약센터}', @dlr_app_nm), '#{예약문의}' , @dlr_tel)
					SET @k_msg_phone = @k_kko_msg
				END

				SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @bk_map_url), '#{url_pc}', @bk_map_url), '\', '')
			END

			-- 실시간 정비 알림.
			IF @sed_kind_cd = 'RW' OR @sed_kind_cd = 'TE' OR @sed_kind_cd = 'TS' OR @sed_kind_cd = 'TU'
			BEGIN
				IF @k_out_fl = 'MOD' OR @k_out_fl = 'MODP' OR @k_out_fl = 'MOD_P' OR @k_out_fl = 'MODP_P'
				BEGIN
					SET @res_code = -1
					SET @res_msg = '실시간 정비 알림톡일 경우, 수정 R/O 에서는 발송되지 않습니다.'
					BREAK;
				END

				SET @k_msg_title = '실시간 정비상황 알림';

				IF @sed_kind_cd = 'RW' OR @sed_kind_cd = 'TE'
				BEGIN
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n정비 진행 상황을 안내 드립니다.' 
					IF @sed_kind_cd = 'TE'
					BEGIN
						SET @ro_status_nm = '정비 종료'
						SET @k_msg_text_02 = '고객님의 차량이 정비가 종료되어 출고 대기 상태입니다.\n\n※ 정비 진행 상황은 ''''정비 대기 → 정비 중 → 정비 종료'''' 단계로 표시됩니다.'''
					END
					IF @sed_kind_cd = 'RW'
					BEGIN	
						SET @ro_status_nm = '정비 대기'
						SET @k_msg_text_02 = '고객님의 차량이 정비 대기 상태입니다.\n\n※ 정비 진행 상황은 ''''정비 대기 → 정비 중 → 정비 종료'''' 단계로 표시됩니다.'''
					END
					
					-- Item List 형태로 변경됨에 따라 temp_cd 에 따른 로직 변경처리
					IF Convert(varchar(8), getdate(), 112) >= '20220810'
					BEGIN
						SET @k_kko_msg = @temp_msg

						SELECT @k_msg_phone = REPLACE(REPLACE(REPLACE(REPLACE(@temp_phone_msg, '#{차량번호}', @k_carno), '#{정비상황}', @ro_status_nm),'#{정비센터}', @dlr_app_nm),
											'#{상담문의}', @dlr_tel)

						SELECT @k_item_data = REPLACE(REPLACE(REPLACE(REPLACE(@temp_item_data, '#{차량번호}', @k_carno), '#{정비상황}', @ro_status_nm),'#{정비센터}', @dlr_app_nm),
											'#{상담문의}', @dlr_tel)
					END
					ELSE
					BEGIN
						SELECT @k_kko_msg = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_msg, '#{텍스트1}', @k_msg_text_01), '#{텍스트2}', @k_msg_text_02), 
												'#{작업구분}', @ro_status_nm), '#{차량번호}', @k_carno), '#{서비스센터}', @dlr_app_nm), '#{전화번호}' , @dlr_tel)
						SET @k_msg_phone = @k_kko_msg 
					END
				END

				IF @sed_kind_cd = 'TU' OR @sed_kind_cd = 'TS'
				BEGIN
					SET @ro_status_nm = '정비 중'

					IF @k_pre_out_dt = '' OR @k_pre_out_dt Is Null OR @k_pre_out_time = '' OR @k_pre_out_time Is Null
					BEGIN
						SET @res_code = -1
						SET @res_msg = '예상종료일시를 확인해주세요.'
						BREAK;
					END

					IF @sed_kind_cd = 'TU'
					BEGIN
						SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n예상종료시간이 변경되었습니다.' 
						SET @k_msg_text_02 = '고객님의 차량 정비가 진행 중입니다.\n\n※ 정비 진행 상황은 ''''정비 대기 → 정비 중 → 정비 종료'''' 단계로 표시됩니다.'''
					END

					IF @sed_kind_cd = 'TS'
					BEGIN
						SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n정비 진행 상황을 안내 드립니다.' 
						SET @k_msg_text_02 = '고객님의 차량 정비가 시작되었습니다.\n\n※ 정비 진행 상황은 ''''정비 대기 → 정비 중 → 정비 종료'''' 단계로 표시됩니다.'''
					END
					
					-- Item List 형태로 변경됨에 따라 temp_cd 에 따른 로직 변경처리
					IF Convert(varchar(8), getdate(), 112) >= '20220810'
					BEGIN
						SET @k_kko_msg = @temp_msg

						SELECT @k_msg_phone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_phone_msg, '#{차량번호}', @k_carno), '#{정비상황}', @ro_status_nm),
											'#{예상종료일자}', @k_pre_out_dt),'#{예상종료시간}', @k_pre_out_time),'#{정비센터}', @dlr_app_nm),
											'#{상담문의}', @dlr_tel)

						SELECT @k_item_data = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_item_data, '#{차량번호}', @k_carno), '#{정비상황}', @ro_status_nm),
											'#{예상종료일자}', @k_pre_out_dt),'#{예상종료시간}', @k_pre_out_time ),'#{정비센터}', @dlr_app_nm),
											'#{상담문의}', @dlr_tel)
					END
					ELSE
					BEGIN
						SELECT @k_kko_msg = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_msg, '#{텍스트1}', @k_msg_text_01), 
											'#{텍스트2}', @k_msg_text_02), '#{작업구분}', @ro_status_nm), '#{차량번호}', @k_carno),
											'#{서비스센터}', @dlr_app_nm), '#{전화번호}' , @dlr_tel), '#{예상종료일자}', @k_pre_out_dt),'#{예상종료시간}', @k_pre_out_time)

						SET @k_msg_phone = @k_kko_msg 
					END

				END
			END

			-- 작업지시서 점검정비견적서, 점검정비명세서, 정기점검표
			IF LEFT(@sed_kind_cd,2) = 'BS' OR LEFT(@sed_kind_cd,2) = 'ES' OR LEFT(@sed_kind_cd,2) = 'RS'
			BEGIN
				IF @sed_kind_cd = 'RS_01' 
				BEGIN 

					SET @k_msg_title = '점검정비견적서'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n점검정비 견적서가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_est_url), '#{url_pc}', @k_print_est_url), '\','')

					SET @k_msg_phone = @k_print_est_url 
					
				END
				IF @sed_kind_cd = 'RS_02' 
				BEGIN 
					SET @k_msg_title = '점검정비 명세서'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n점검정비 명세서가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_invoice_url), '#{url_pc}', @k_print_invoice_url), '\','')

					SET @k_msg_phone = @k_print_invoice_url 
				END
				IF @sed_kind_cd = 'RS_03' 
				BEGIN 
					SET @k_msg_title = '정기점검표'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n정기점검표가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_check_url), '#{url_pc}', @k_print_check_url), '\','')

					SET @k_msg_phone = @k_print_check_url 
				END
				IF @sed_kind_cd = 'RS_04' 
				BEGIN 
					SET @k_msg_title = '점검정비명세서, 정기점검표'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n점검정비 명세서, 정기점검표가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_invoice_url), '#{url_pc}', @k_print_invoice_url), '\','')
					SELECT @k_btn_url_02 = REPLACE(REPLACE(REPLACE(@temp_btn_url_02, '#{url_mobile}', @k_print_check_url), '#{url_pc}', @k_print_check_url), '\','')

					SET @k_msg_phone = '[점검정비 명세서]\n\n ' + @k_print_invoice_url + '\n\n[정기점검표] \n\n' + @k_print_check_url
				END
				IF @sed_kind_cd = 'RS_05' 
				BEGIN 
					SET @k_msg_title = '점검정비견적서, 정기점검표'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n점검정비 견적서, 정기점검표가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_est_url), '#{url_pc}', @k_print_est_url), '\','')
					SELECT @k_btn_url_02 = REPLACE(REPLACE(REPLACE(@temp_btn_url_02, '#{url_mobile}', @k_print_check_url), '#{url_pc}', @k_print_check_url), '\','')

					SET @k_msg_phone = '[점검정비 견적서]\n\n' + @k_print_est_url  + '\n\n[정기점검표] \n\n' + @k_print_check_url
				END
				IF @sed_kind_cd = 'RS_06' 
				BEGIN 
					SET @k_msg_title = '점검정비견적서, 점검정비명세서'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n점검정비 견적서, 점검정비 명세서가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_est_url), '#{url_pc}', @k_print_est_url), '\','')
					SELECT @k_btn_url_02 = REPLACE(REPLACE(REPLACE(@temp_btn_url_02, '#{url_mobile}', @k_print_invoice_url), '#{url_pc}', @k_print_invoice_url), '\','')

					SET @k_msg_phone = '[점검정비 견적서]\n\n' + @k_print_est_url  +'\n\n[점검정비 명세서]\n\n ' + @k_print_invoice_url 
				END
				IF @sed_kind_cd = 'RS_07' 
				BEGIN 
					SET @k_msg_title = '점검정비견적서, 점검정비명세서, 정기점검표'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n점검정비 견적서, 점검정비 명세서, 정기점검표가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_est_url), '#{url_pc}', @k_print_est_url), '\','')
					SELECT @k_btn_url_02 = REPLACE(REPLACE(REPLACE(@temp_btn_url_02, '#{url_mobile}', @k_print_invoice_url), '#{url_pc}', @k_print_invoice_url), '\','')
					SELECT @k_btn_url_03 = REPLACE(REPLACE(REPLACE(@temp_btn_url_03, '#{url_mobile}', @k_print_check_url), '#{url_pc}', @k_print_check_url), '\','')

					SET @k_msg_phone = '[점검정비 견적서]\n\n' + @k_print_est_url  +'\n\n[점검정비 명세서]\n\n ' + @k_print_invoice_url + '\n\n[정기점검표] \n\n' +@k_print_check_url
				END
				
				-- 점검정비견적서 알림톡 발송
				IF @sed_kind_cd = 'BS_01' OR @sed_kind_cd = 'ES_01'
				BEGIN

					SET @k_msg_title = '점검정비견적서'
					SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n점검정비 견적서가 도착하였습니다.' 
					SELECT @k_btn_url_01 = REPLACE(REPLACE(REPLACE(@temp_btn_url_01, '#{url_mobile}', @k_print_est_url), '#{url_pc}', @k_print_est_url), '\','')

					SET @k_msg_phone = @k_print_est_url
				END

				-- Item List 형태로 변경됨에 따라 temp_cd 에 따른 로직 변경처리.
				IF Convert(varchar(8), getdate(), 112) >= '20220810'
				BEGIN

					SET @k_kko_msg = @temp_msg
					
					SELECT @k_msg_phone = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_phone_msg, '#{차량번호}', @k_carno), '#{정비센터}', @dlr_app_nm),
											'#{상담문의}', @dlr_tel),'#{점검정비 견적서 url}', @k_print_est_url), '#{점검정비 명세서 url}', @k_print_invoice_url),
											'#{정기점검표 url}', @k_print_check_url)

					SELECT @k_item_data = REPLACE(REPLACE(REPLACE(@temp_item_data, '#{차량번호}', @k_carno), '#{정비센터}', @dlr_app_nm),
											'#{상담문의}', @dlr_tel)
				END			 
				ELSE
				BEGIN
					SELECT @k_kko_msg = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_msg, '#{텍스트1}', @k_msg_text_01), '#{텍스트2}', @k_msg_text_02), 
										'#{서비스센터}', @dlr_app_nm), '#{차량번호}', @k_carno), '#{전화번호}', @dlr_tel)
					SET @k_msg_phone = @k_kko_msg + @k_msg_phone
				END		
			END

			IF @sed_kind_cd = 'HC'
			BEGIN
				SET @k_msg_title = '고객만족도 조사'
				SET @k_msg_text_01 = '고객님, 서비스 바이 볼보입니다.\n\n차량 출고 이후 불편한 점은 없으신가요?' 
				SET @k_msg_text_02 = '행 중 문의 사항이나 도움이 필요하신 경우, 서비스센터로 연락을 주시면 친절히 상담 도와드리겠습니다.\n\n저희 볼보자동차 서비스센터를 이용해주셔서 감사합니다.' 

				-- Item List 형태로 변경됨에 따라 temp_cd 에 따른 로직 변경처리
				IF Convert(varchar(8), getdate(), 112) >= '20220810'
				BEGIN
					SET @k_kko_msg = @temp_msg

					SELECT @k_msg_phone = REPLACE(REPLACE(REPLACE(@temp_phone_msg, '#{차량번호}', @k_carno), '#{출고센터}', @dlr_app_nm),
										'#{상담문의}', @dlr_tel)
					SELECT @k_item_data = REPLACE(REPLACE(REPLACE(@temp_item_data, '#{차량번호}', @k_carno), '#{출고센터}', @dlr_app_nm),
										'#{상담문의}', @dlr_tel)
				END
				ELSE
				BEGIN

					SELECT @k_kko_msg = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@temp_msg, '#{텍스트1}', @k_msg_text_01), '#{텍스트2}', @k_msg_text_02), 
									'#{출고일자}', @k_out_dt), '#{차량번호}',@k_carno), '#{서비스센터}', @dlr_app_nm), '#{문의번호}' , @dlr_tel)

					SET @k_msg_phone = @k_kko_msg + @k_msg_phone
				END
			END

			-- 카카오 알림톡 발송 실패시, 문자로 대체되는데 문자 발송을 SMS, LMS 나누는 기준.
			IF DATALENGTH(@k_msg_phone) > 80 
			BEGIN
				SET @k_msg_type = 'KM'
			END
			ELSE
			BEGIN
				SET @k_msg_type = 'KS'
			END
			
			-- KAKAO_RESULT 생성 테이블 reserved10 에 전달하여 API에서 처리
			SET @k_result_insert =	@k_result_table		+  ''''		+ @k_msg_key	+ ''',''' + @sed_dlr_cd		+ ''',''' + @k_msg_data			+ ''','''	+ @k_carno			+ ''','''	+ @k_cust_tel		+ ''','''	+
									@sed_kind_cd		+ ''','''	+ @temp_cd		+ ''',''' + @temp_type		+ ''',''' + @k_print_est_key	+ ''','''	+ @k_print_invoice_key	+ ''','''	+ 
									@k_print_check_key	+ ''',getdate(),'''			+ @data_in_user				+ ''','''			+ @sed_send_client +	''')'

			-- Json 문자열 합치기			
			INSERT INTO @temp_json
			SELECT  REPLACE(col1, '\\', '\')
			  FROM (
					SELECT *
					  FROM (
							SELECT 	@k_kko_msg AS KKO_MSG,			@temp_cd AS KKO_TEMPLATE_CD, 				@temp_type AS KKO_TEMPLATE_TYPE,		@k_msg_title AS TITLE,
									@k_msg_phone AS PHONE_MSG,		'S' AS SEND_TYPE,							@k_msg_type AS MSG_TYPE,				@k_cust_tel AS MOBILE_NO,
									@sender_no AS SENDER_NO,		@client_id AS CLIENT_ID,					'' AS KKO_APP_USER_ID,					'' AS RESERVE_DATE,
									'' AS MMS_IMG1,					'' AS MMS_IMG2,								'' AS MMS_IMG3,			
									CASE WHEN @k_btn_url_01 = '' OR @k_btn_url_01 Is Null THEN '""' ELSE JSON_QUERY(@k_btn_url_01)END AS KKO_BTN_LINK1,
									CASE WHEN @k_btn_url_02 = '' OR @k_btn_url_02 Is Null THEN '""' ELSE JSON_QUERY(@k_btn_url_02)END AS KKO_BTN_LINK2,
									CASE WHEN @k_btn_url_03 = '' OR @k_btn_url_03 Is Null THEN '""' ELSE JSON_QUERY(@k_btn_url_03)END AS KKO_BTN_LINK3,
									CASE WHEN @k_btn_url_04 = '' OR @k_btn_url_04 Is Null THEN '""' ELSE JSON_QUERY(@k_btn_url_04)END AS KKO_BTN_LINK4,
									CASE WHEN @k_btn_url_05 = '' OR @k_btn_url_05 Is Null THEN '""' ELSE JSON_QUERY(@k_btn_url_05)END AS KKO_BTN_LINK5,
									'' AS TAX_CD1,					'' AS TAX_CD2,								'' AS NAT_CD,							'' AS KKO_QUICK_REPLY1,
									'' AS KKO_QUICK_REPLY2,			'' AS KKO_QUICK_REPLY3,						'' AS KKO_QUICK_REPLY4,					'' AS KKO_QUICK_REPLY5,
									'' AS KKO_QUICK_REPLY10,		'' AS EMPHASIZE_TITLE,		
									'' AS KKO_QUICK_REPLY6,			'' AS KKO_QUICK_REPLY7,						'' AS KKO_QUICK_REPLY8,					'' AS KKO_QUICK_REPLY9,
									@temp_item_header AS HEADER,	'' AS ITEM_HIGHLIGHT,
									CASE WHEN @k_item_data = '' OR @k_item_data Is Null THEN '""' ELSE JSON_QUERY(@k_item_data)END AS ITEM,
									@company AS company,			@k_brand AS brand,							@department AS department,
									@dlr_comp_no AS business_number,@sed_dlr_cd AS user_code,					@dlr_app_nm AS user_name,				CONVERT(Varchar, @k_cust_cd) AS customer_code,
									@sed_kind_cd AS message_kind,	UPPER(@input_user_id) AS register_userid,	@input_user_nm AS register_username,	@k_vin AS vin,
									@k_carno AS plateno,			@k_msg_data AS rono,						@k_msg_key AS reserved01,				'' AS reserved02,
									'' AS reserved03,				'' AS reserved04,							'' AS reserved05,						'' AS reserved06,
									'' AS reserved07,				'' AS reserved08,							'' AS reserved09,						@k_result_insert AS reserved10
							) AS A
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
				   ) AS A (col1)
			-- WITHOUT_ARRAY_WRAPPER   : JSON에서 대괄호 제거
			
			FETCH NEXT FROM CUR_KAKAO_JSON INTO @k_msg_data
		END
	CLOSE CUR_KAKAO_JSON
	DEALLOCATE CUR_KAKAO_JSON

	DECLARE @data_cnt int

	SELECT @data_cnt = COUNT(0)
	  FROM @temp_json

	IF @data_cnt > 0 
	BEGIN
		-- Json Data 최종 합치는 작업.
		SET @res_code = 0
		SELECT @res_msg  = '[' + STRING_AGG(json_temp, ',') + ']' FROM @temp_json
	END 
	
	ERROR:
	SELECT @res_code AS res_code, @res_msg AS res_msg, @kakao_if_url AS kakao_if_url
	
END TRY

BEGIN CATCH
	
	-- Cursor 실행 중 오류 발생시, cursor 강제 종료.
	IF (CURSOR_STATUS('global', 'CUR_KAKAO_JSON') >= 0)
	BEGIN
		CLOSE CUR_KAKAO_JSON
		DEALLOCATE CUR_KAKAO_JSON
	END

	SET @res_code = -1;		
	SET @res_msg = '[' + ERROR_PROCEDURE() + '] 프로시져 실행 중 오류가 발생하였습니다. Error Line : ' + CONVERT(VARCHAR, ERROR_LINE()) + ' / Error Message : ' + ERROR_MESSAGE();

	SELECT @res_code AS res_code, @res_msg AS res_msg, @kakao_if_url AS kakao_if_url
END CATCH
