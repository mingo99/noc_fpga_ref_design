`include "svc_loader_util.svi"
`include "svc_util_parms.v"
`include "svc_util_macros.v"
`include "pciesvc_application_parms.v"
`include "pciesvc_ll_parms.v"
`include "pciesvc_ll_msgcodes.v"
`include "pciesvc_phylayer_msgcodes.v"
`include "pciesvc_parms.v"
`include "pciesvc_tlp_parms.v"

class pciesvc_device_serdes_x16_model_config;

  string DISPLAY_NAME = "pciesvc_device_serdes_x16_model";
  bit [7:0]  enable_vc = 8'b00000001;
  bit [11:0] step_pkt_length;
  rand int root_link_width;
  rand int endpoint_root_link_width;
        bit rand_infinite_credit;
  int max_acknak_latency_timer = 0;
        int min_acknak_latency_timer = 0;
        bit [11:0] min_pkt_size_to_dut = 'd12;
        bit [11:0] max_pkt_size_to_dut = 'd4088;
  bit [11:0] min_pkt_size_from_dut = 'd8;
  bit [11:0] max_pkt_size_from_dut = 'd4088;
        int pkt_length_step_size = 'd1;
        int measure_prop_delay = 'd0;
        int auto_header_mode_percentage = 'd0;
        int additional_timeout = 'd0;
     bit [11:0] min_pktgen_ipg; 
  bit [11:0] max_pktgen_ipg = 'd1;
        int num_cr_to_dut = 'd100;
        int num_cr_from_dut = 'd100;
  int link_width = 'd4;
        int root_digest_percentage = 'd0;
        int endpoint_digest_percentage = 'd0;
  int num_tests_to_run = 'd10;
  reg[256*8-1:0] msglog_transaction_file="";
  bit mem64bit_en;
  bit updatebars_en;
  randc bit [2:0] bar_mem64bit_en;
        rand bit [31:0] root_supported_speeds, endpoint_supported_speeds;
        rand bit [11:0] max_payload_size;
        rand int en_retry_ei;
        rand bit [7:0] hdr_credit_p, hdr_credit_np, hdr_credit_cpl;  
        rand bit [10:0]  data_credit_p, data_credit_np, data_credit_cpl;
  string pcie_ep_max_speed="PIPE_RATE_32G";  //default is Gen5
//  rand bit [31:0] root_supported_speeds, endpoint_supported_speeds;

        constraint max_payload_size_c{
             soft  max_payload_size == 512;
  }  

  constraint en_retry_ei_c{
              soft en_retry_ei == 0;
        }


  constraint en_mem64bit_bars_c{
              bar_mem64bit_en == 0; 

        }    
  constraint hdr_credits_p_c{
              
              if (rand_infinite_credit == 0) 
          hdr_credit_p inside {[10:1027]};
        else
          hdr_credit_p == 0; 
        }

  constraint hdr_credits_np_c{
              
              if (rand_infinite_credit == 0) 
          hdr_credit_np inside {[10:127]};
        else
          hdr_credit_np == 0; 
        }

  constraint hdr_credits_cpl_c{
              
              if (rand_infinite_credit == 0) 
          hdr_credit_p inside {[10:127]};
        else
          hdr_credit_p == 0; 
        }


  constraint data_credits_p_c{
              
              if (rand_infinite_credit == 0) 
          data_credit_p inside {[1200:2000]};
        else
          data_credit_p == 0; 
        }

  constraint data_credits_np_c{
              
              if (rand_infinite_credit == 0) 
          data_credit_np inside {[1200:2000]};
        else
          data_credit_np == 0; 
        }

  constraint data_credits_cpl_c{
              
              if (rand_infinite_credit == 0) 
          data_credit_cpl inside {[10:127]};
        else
          data_credit_cpl == 0; 
        }

  constraint root_supported_speeds_c{
            soft root_supported_speeds dist {5:= 80, 4:=5, 3:= 5, 2:=5, 1:=5}; 
        }

  constraint endpoint_supported_speeds_c{
      soft endpoint_supported_speeds dist {5:= 80, 4:=5, 3:= 5, 2:=5, 1:=5}; 
        }

        function void post_randomize();
             if(root_link_width == 0) begin
                 root_link_width = 1 << $urandom_range(0,2);
             end
        endfunction
              

  function new(string name="pciesvc_device_serdes_x16_model_config");

    if($value$plusargs ("enable_vc=%b", enable_vc))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO enable_vc = 0x%0h", DISPLAY_NAME, enable_vc);
    end

    if($value$plusargs ("step_pkt_length=%d", step_pkt_length))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO step_pkt_length = %0d", DISPLAY_NAME, step_pkt_length);
    end

    if($value$plusargs ("max_acknak_latency_timer=%d", max_acknak_latency_timer))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO max_acknak_latency_timer = %0d", DISPLAY_NAME, max_acknak_latency_timer);
    end

    if($value$plusargs ("min_acknak_latency_timer=%d", min_acknak_latency_timer))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO min_acknak_latency_timer = %0d", DISPLAY_NAME, min_acknak_latency_timer);
    end

    if($value$plusargs ("min_pkt_size_to_dut=%d", min_pkt_size_to_dut))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO min_pkt_size_to_dut = %0d", DISPLAY_NAME, min_pkt_size_to_dut);
    end

    if($value$plusargs ("rand_infinite_credit=%d", rand_infinite_credit))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO rand_infinite_credit = %0d", DISPLAY_NAME, rand_infinite_credit);
    end

    if($value$plusargs ("max_pkt_size_to_dut=%d", max_pkt_size_to_dut))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO max_pkt_size_to_dut = %d", DISPLAY_NAME, max_pkt_size_to_dut);
    end

    if($value$plusargs ("min_pkt_size_from_dut=%d", min_pkt_size_from_dut))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO min_pkt_size_from_dut = %0d", DISPLAY_NAME, min_pkt_size_from_dut);
    end

    if($value$plusargs ("max_pkt_size_from_dut=%d", max_pkt_size_from_dut))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO max_pkt_size_from_dut = %0d", DISPLAY_NAME, max_pkt_size_from_dut);
    end

    if($value$plusargs ("pkt_length_step_size=%d", pkt_length_step_size))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO pkt_length_step_size = %0d", DISPLAY_NAME, pkt_length_step_size);
    end

    if($value$plusargs ("auto_header_mode_percentage=%d", auto_header_mode_percentage))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO auto_header_mode_percentage = %0d", DISPLAY_NAME, auto_header_mode_percentage);
    end

    if($value$plusargs ("additional_timeout=%d", additional_timeout))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO additional_timeout = %0d", DISPLAY_NAME, additional_timeout);
    end

    if($value$plusargs ("min_pktgen_ipg=%d", min_pktgen_ipg))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO min_pktgen_ipg = %0d", DISPLAY_NAME, min_pktgen_ipg);
    end

    if($value$plusargs ("max_pktgen_ipg=%d", max_pktgen_ipg))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO max_pktgen_ipg = %0d", DISPLAY_NAME, max_pktgen_ipg);
    end

    if($value$plusargs ("measure_prop_delay=%d", measure_prop_delay))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO measure_prop_delay = %0d", DISPLAY_NAME, measure_prop_delay);
    end

    if($value$plusargs ("num_cr_to_dut=%d", num_cr_to_dut))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO num_cr_to_dut = %0d", DISPLAY_NAME, num_cr_to_dut);
    end

    if($value$plusargs ("num_cr_from_dut=%d", num_cr_from_dut))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO num_cr_from_dut = %0d", DISPLAY_NAME, num_cr_from_dut);
    end

    if($value$plusargs ("link_width=%d", link_width))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO link_width = %0d", DISPLAY_NAME, link_width);
    end

    if($value$plusargs ("root_digest_percentage=%d", root_digest_percentage))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO root_digest_percentage = %0d", DISPLAY_NAME, root_digest_percentage);
    end

    if($value$plusargs ("endpoint_digest_percentage=%d", endpoint_digest_percentage))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO endpoint_digest_percentage = %0d", DISPLAY_NAME, endpoint_digest_percentage);
    end

    if($value$plusargs ("num_tests_to_run=%d", num_tests_to_run))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO num_tests_to_run = %0d", DISPLAY_NAME, num_tests_to_run);
    end


    if ($value$plusargs ("root_link_width=%d", root_link_width))begin
                      root_link_width.rand_mode(0);
    end
  

    if ($value$plusargs ("root_supported_speeds=%d", root_supported_speeds))begin
      root_supported_speeds.rand_mode(0);
          end

    if ($value$plusargs ("endpoint_supported_speeds=%d", endpoint_supported_speeds))begin
      endpoint_supported_speeds.rand_mode(0);
          end

    $msglog(LOG_INFO, "%sconfig: TEST_INFO root_link_width = %0d, root_supported_speeds = %0d, endpoint_supported_speeds = %0d",
      DISPLAY_NAME, root_link_width, root_supported_speeds, endpoint_supported_speeds);  

    if ($value$plusargs ("msglog_transaction_file=%s", msglog_transaction_file))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO msglog_transaction_file = %s", DISPLAY_NAME, msglog_transaction_file);
          end

    if($value$plusargs ("pcie_ep_max_speed=%s", pcie_ep_max_speed))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO pcie_ep_max_speed = %s", DISPLAY_NAME, pcie_ep_max_speed);
    end

    if($value$plusargs ("mem64bit_en=%d", mem64bit_en))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO mem64bit_en = %0d", DISPLAY_NAME, mem64bit_en);
    end

    if($value$plusargs ("updatebars_en=%d", updatebars_en))begin
      $msglog(LOG_INFO, "%sconfig: TEST_INFO updatebars_en = %0d", DISPLAY_NAME, updatebars_en);
    end


  endfunction




endclass
