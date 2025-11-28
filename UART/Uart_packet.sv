
import enum_pkg::*;	

	
	// Covarage I am tried to add  covergroup in the class but it give me error 	
	    /*
			** Error: Variables of embedded Covergroup type 'cg' cannot be created.
			** Error: near "=": syntax error, unexpected '='
						
		 */    
	
	covergroup cg with function sample(parity_t p, logic [7:0] d);
		cp1: coverpoint p;
		cp2: coverpoint d {
			bins all_zeros = {8'h00};
			bins all_ones  = {8'hFF};
			bins others    = default;
		}
	endgroup: cg
	
	
	
	class Uart_packet;
		
		
		bit	clk ;			
		
			
		rand parity_t parity_type;

		
		// Dynamic array 
			rand logic [7:0] dyn[];
		
		// Associative array for actual DUT results 
			logic [7:0] actual_assoc[int];
		
		// Associative array for expected results
			logic [7:0] expected_assoc [int];
		
		
		////////// constraint /////////////
			
			constraint dyn_size_c{
				dyn.size() inside {[5:20]};
			}
			
			constraint dyn_element_c{
				foreach(dyn[i])
					dyn[i] dist {'h00 :/ 1 ,'hff :/ 1,['h00 :'hff] :/ 98};
				
			}
			
			constraint parity_type_C{
				parity_type dist {NO_PARITY := 2 ,ODD_PARITY := 4 , EVEN_PARITY := 4};
				parity_type inside {NO_PARITY, ODD_PARITY, EVEN_PARITY};
			}
				
					
		
		// Covarage
			 
			cg cg_f;  

		   function new();
			  cg_f = new(); 
		   endfunction
			
		
		/////////// function And task //////////////// 	

			task automatic drive_stim(
			ref logic clk,
			ref logic tx_start,
			ref logic parity_en,
			ref logic even_parity,
			ref logic [7:0] data_in,
			ref logic tx,
			ref logic tx_busy
		);
			logic [7:0] reconstructed;
			logic parity_bit;

			foreach (dyn[i]) begin
			
				parity_en   = (parity_type != NO_PARITY);
				even_parity = (parity_type == EVEN_PARITY);
				data_in     = dyn[i];

				
				@(negedge clk);
				tx_start = 1;
				@(negedge clk);
				tx_start = 0;

			
				@(posedge clk);
				wait (tx_busy == 1);

				@(negedge clk);
				reconstructed = '0;


				
				
				for (int b = 7; b >= 0; b--) begin
					@(negedge clk);
					reconstructed[b] = tx;
					#1;
				end
				
				
				golden_model(dyn[i]);
				collect_output_data(reconstructed);
				cg_f.sample(parity_type, reconstructed);
				
				
				if (parity_en) begin
					@(negedge clk);
					#1;
					parity_bit = tx;
				end

			
				@(negedge clk);



				$display("[%0t] SENT: 0x%0h  GOT: 0x%0h  parity_en=%b parity_type=%0s",
						 $time, dyn[i], reconstructed, parity_en, parity_type.name());
			end
		endtask



		
			task automatic golden_model(logic [7:0] data);
				int exp_idx = expected_assoc.num();
				expected_assoc[exp_idx] = data;
			endtask

			
			task collect_output_data(logic [7:0] Out);
				int exp_idx = actual_assoc.num();
				actual_assoc[exp_idx] = Out;
			endtask

			
			task check_results();				 
				for (int i = 0; i < expected_assoc.size(); i++) begin
				  if (actual_assoc[i] == expected_assoc[i])
					$display("[PASS] Index %0d: Expected = %0d, Got = %0d", i, expected_assoc[i], actual_assoc[i]);
				  else
					$display("[FAIL] Index %0d: Expected = %0d, Got = %0d", i, expected_assoc[i], actual_assoc[i]);
				end
			endtask
			
			
			
		

			
	endclass : Uart_packet
	


	