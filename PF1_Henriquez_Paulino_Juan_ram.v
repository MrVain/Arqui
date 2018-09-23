					//TESTER
module Ram_access;
integer fi, fo, code, i; reg [31:0] data;
reg Enable; reg [31:0] DataIn; wire almostdone, done;
reg [5:0] opcode;
reg [8:0] Address; wire [31:0] DataOut;
reg preload_done;
reg [4:0] count;

ram512x8 ram1 (DataOut, Enable, Address, DataIn, opcode, almostdone, done);

initial begin
    fi = $fopen("input_file.txt", "r");
    Address = 9'b000000000;
    while (!$feof(fi)) begin
        code = $fscanf(fi, "%b", data);
        ram1.Mem[Address] = data;
        Address = Address + 1;
    end
    $fclose(fi); 
    count = 5'd0;
end

//printing module
always @ (posedge done) begin
    count = count + 1;
    if(opcode[5:3]==3'b101) begin
    case(opcode[2:0])
        3'b000: begin
        $display("%d: store byte:", count[3:0]);
        end
        3'b001: begin
        $display("%d: store halfword:", count[3:0]);
        end
        3'b011: begin
        $display("%d: store word:", count[3:0]);
        end
    endcase
    $display("sent to ram: opcode= %b, address= %h, data=%b", opcode, Address, DataIn);
    $display("data in ram: address %h, data is %b", Address, ram1.Mem[Address]);
    $display("store done");
    $display("----------------------------------------------------");
    end else begin
    case(opcode[2:0])
        3'b000: begin
        $display("%d: load byte:", count[3:0]);
        end
        3'b001: begin
        $display("%d: load halfword:", count[3:0]);
        end
        3'b011: begin
        $display("%d: load word:", count[3:0]);
        end
    endcase
    $display("sent to ram: opcode= %b, address= %h", opcode, Address);
    $display("data received: address %h, data is %b", Address, DataOut);
    //$display("data in RAM: address %h , data is %b", Address, ram1.Mem[Address]);
    $display("load done");
    $display("----------------------------------------------------");    
    end
end

//actual ram handler
initial #200 begin
    $display("enter");
    Address = 9'd4;
    // DataIn = 8'b10101010;
    opcode = 6'b100001;
    #2 Enable = 1'b0;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    //escribir un byte en la localización 0
    Address = 9'd0;
    opcode = 6'b101000;
    DataIn = 32'b10101010;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    //un halfword en la localización 2
    Address = 9'd2;
    opcode = 6'b101001;
    DataIn = 32'b0010101011111111;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    // un halfword en la localización 4
    Address = 9'd4;
    opcode = 6'b101001;
    DataIn = 32'b0111111110101010;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    //un word en la localización 8
    Address = 9'd8;
    opcode = 6'b101011;
    DataIn = 32'b10101010111111111010101011111111;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    //Entonces deben leer un byte de la localización 0
    Address = 9'd0;
    opcode = 6'b100000;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    //un halfword de la localización 2  
    Address = 9'd2;
    opcode = 6'b100001;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    // un halfword de la localización 4
    Address = 9'd4;
    opcode = 6'b100001;
    #3 Enable = 1'b1;
    #2 Enable = 1'b0;
    // un word de la localización 8
    Address = 9'd8;
    opcode = 6'b100011;
    #3 Enable = 1'b1;

end
endmodule

				//ACTUAL RAM
module ram512x8(output reg [31:0] DataOut, input Enable, input [8:0] Address, input [31:0] DataIn,
                    input [5:0] opcode, output reg almostdone = 1'b0, output reg done );
//input needst to have at least 9 because 2^9 = 512
reg [7:0] Mem[0:512]; //128 localizaciones de 32 bits
reg [7:0] zero = 8'b00000000;
reg [7:0] one = 8'b11111111;
always @ (Enable) begin
    done = 1'b0;
    if(Enable)
        begin
                //Mem[Address] = 3'o000 + DataIn[7:0];
            case(opcode)
                6'b101000: //store byte
                begin  
                    Mem[Address] = DataIn[7:0];
                end
                6'b101001: //store halfword
                begin
                    Mem[Address] = DataIn[15:8];
                    Mem[Address+1] = DataIn[7:0];
                    //for storing, we store the most significant byte in the address
                    //and the least significant byte we store on the next address
                end
                6'b101011: //store word
                begin
                    Mem[Address] = DataIn[31:24];
                    Mem[Address+1] = DataIn[23:16];
                    Mem[Address+2] = DataIn[15:8];
                    Mem[Address+3] = DataIn[7:0];
                end
                //pending double word
                6'b111101: //store souble word
                begin
                    if(!almostdone)
                    begin
                        Mem[Address] = DataIn[31:24];
                        Mem[Address+1] = DataIn[23:16];
                        Mem[Address+2] = DataIn[15:8];
                        Mem[Address+3] = DataIn[7:0];
                        almostdone = 1'b1;
                    end
                     else 
                    begin
                        Mem[Address+4] = DataIn[31:24];
                        Mem[Address+5] = DataIn[23:16];
                        Mem[Address+6] = DataIn[15:8];
                        Mem[Address+7] = DataIn[7:0];
                        almostdone = 1'b0;
                    end
                end
                //all load intructions
                6'b100000: //load byte 
                begin 
                    //signed negative byte
                    if(Mem[Address][7] == 1'b1)
                    begin
                        DataOut[31:24] = one;
                        DataOut[23:16] = one;
                        DataOut[15:8] = one;
                        DataOut[7:0] = Mem[Address];
                        //since it's big indian i save the most significant first
                        //which can't be appreciated here... but on the next
                    end
                    else  
                    begin
                        //signed positive byte
                        DataOut[31:24] = zero;
                        DataOut[23:16] = zero;
                        DataOut[15:8] = zero;
                        DataOut[7:0] = Mem[Address];
                    end
                    
                end
                6'b100001: //load halfword
                begin
                    //signed negative halfword
                    if(Mem[Address][7] == 1'b1)
                    begin
                        DataOut[31:24] = one;
                        DataOut[23:16] = one;
                        DataOut[15:8] = Mem[Address];
                        DataOut[7:0] = Mem[Address+1];
                        //here you can see that we loaded the first adress, to the most significant bits
                        //and the next adress as the the least significant bits.
                    end
                    else 
                    begin
                        DataOut[31:24] = zero;
                        DataOut[23:16] = zero;
                        DataOut[15:8] = Mem[Address];
                        DataOut[7:0] = Mem[Address+1];
                    end
                    
                end
                6'b100011: //load word
                begin
                    //here i don't need to add sign-extension, because it's already 32 bits
                    //and the sign information should be included already. 
                    DataOut[31:24] = Mem[Address];
                    DataOut[23:16] = Mem[Address+1];
                    DataOut[15:8] = Mem[Address+2];
                    DataOut[7:0] = Mem[Address+3];
                end
                6'b100100: //load unsigned byte
                begin
                    DataOut[31:24] = zero;
                    DataOut[23:16] = zero;
                    DataOut[15:8] = zero;
                    DataOut[7:0] = Mem[Address];
                end
                6'b100101: //load unsigned halfword
                begin
                    DataOut[31:24] = zero;
                    DataOut[23:16] = zero;
                    DataOut[15:8] = Mem[Address];
                    DataOut[7:0] = Mem[Address+1];
                end
                //pending double word
                6'b110101: //load double word
                begin
                    if(!almostdone) // most significant byte from the adress and then
                                    //least significant byte 7 spaces up
                    begin
                        DataOut[31:24] = Mem[Address];
                        DataOut[23:16] = Mem[Address+1];
                        DataOut[15:8] = Mem[Address+2];
                        DataOut[7:0] = Mem[Address+3];
                        almostdone = 1'b1;
                    end
                    else
                    begin 
                        DataOut[31:24] = Mem[Address+4];
                        DataOut[23:16] = Mem[Address+5];
                        DataOut[15:8] = Mem[Address+6];
                        DataOut[7:0] = Mem[Address+7];
                        almostdone = 1'b0;
                    end
                end
            endcase
            done = 1'b1;
    end
end
endmodule