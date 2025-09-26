class apb_sequence extends uvm_sequence#(apb_sequence_item); // normal sequence .....
  `uvm_object_utils(apb_sequence)
  
  function new(string name = "apb_sequence");
    super.new(name);
  endfunction
  
  task body();
    repeat(`no_of_transaction) begin
      req = apb_sequence_item::type_id::create("req");
      wait_for_grant();
      void'(req.randomize()); 
      send_request(req);
      wait_for_item_done();
    end 
  endtask
endclass

class apb_sequence_write_read extends apb_sequence;
  `uvm_object_utils(apb_sequence_write_read)
  
  bit OP;
  int count;
  bit [`ADDR_WIDTH-2:0] addr;
  
  function new(string name = "apb_sequence_write_read");
    super.new(name);
  endfunction
  
  task body();
    repeat(`no_of_transaction )begin
      req = apb_sequence_item::type_id::create("req");
      wait_for_grant();
      void'(req.randomize() with {req.READ_WRITE == OP; req.apb_write_paddr[`ADDR_WIDTH-2:0] == addr; req.apb_write_paddr[`ADDR_WIDTH-1] == 0; } ); // select slave0 or slave1 for operation !.....
      send_request(req);
      wait_for_item_done();
      OP = ~OP; // To take alternative write read operations !
      count++;
      if(count == 2) begin  // for every write followed by read !!
        count =0;
        addr++; // incrementing the address
      end
    end 
  endtask
  
endclass

class apb_sequence_different_slave extends apb_sequence;
  `uvm_object_utils(apb_sequence_different_slave)
 
  bit OP, slave_select; // slave select for alternative selection !
  int count;
  bit [`ADDR_WIDTH-2:0] addr;
  
  function new(string name = "apb_sequence_different_slave");
    super.new(name);
  endfunction
  
  task body();
    count = 0;
    OP = 0;
    repeat(`no_of_transaction ) begin
      req = apb_sequence_item::type_id::create("req");
      wait_for_grant();
      void'(req.randomize() with {req.READ_WRITE == OP; req.apb_write_paddr[`ADDR_WIDTH-2:0] == addr; req.apb_write_paddr[`ADDR_WIDTH-1] == slave_select; } ); // alternating slave .....
      send_request(req);
      wait_for_item_done();
      OP = ~OP; // To take alternative write read operations !
      count++;
      if(count == 2) begin  // for every write followed by read !!
        count =0;
        addr++; // incrementing the address
        slave_select = ~slave_select;
      end
    end 
  endtask 
endclass

class apb_sequence_transfer_t extends apb_sequence;
  `uvm_object_utils(apb_sequence_transfer_t)
  bit trans_scl, OP;
  int count;
  bit [`ADDR_WIDTH-2:0] addr;
  
  function new(string name = "apb_sequence_transfer_t");
    super.new(name);
  endfunction
  
  task body();
    repeat(`no_of_transaction) begin
      req = apb_sequence_item::type_id::create("req");
      wait_for_grant();
      void'(req.randomize() with {req.READ_WRITE == OP; req.apb_write_paddr[`ADDR_WIDTH-2:0] == addr; req.apb_write_paddr[`ADDR_WIDTH-1] == 0; req.transfer == trans_scl;} ); // const slave with toggling transfer for every 2nd operation !!
      send_request(req);
      wait_for_item_done();
      OP = ~OP; // write read conti....
      count++;
      if(count == 2) begin
        count = 0;
        addr = addr + 4;
        trans_scl = ~trans_scl;
      end
    end 
  endtask
endclass

class apb_continuous_write_read extends apb_sequence; // 5 write and 5-read continuous  operation !!
  `uvm_object_utils(apb_continuous_write_read)
  bit OP;
  int count;
  bit [`ADDR_WIDTH-2:0] addr,temp_addr;
  
  function new(string name = "apb_continuous_write_read");
    super.new(name);
  endfunction
  
  task body();
    addr = $urandom(); // random address !
    temp_addr = addr; // store it in temperary variable
    repeat(`no_of_transaction) begin
      req = apb_sequence_item::type_id::create("req");
      wait_for_grant();
      void'(req.randomize() with {req.READ_WRITE == OP; req.apb_write_paddr[`ADDR_WIDTH-2:0] == addr; req.apb_write_paddr[`ADDR_WIDTH-1] == 0;}  ); 
      send_request(req);
      wait_for_item_done();
      count++;
      addr++; // change addr by 1 each time to write/read to/from new addr !!
      if(count == 5) begin
        OP = ~OP; // write read conti....
        addr = temp_addr; // get the address back for read operation !!
      end
      if(count == 10) begin
        count = 0; // clear the counter !!
        addr = $urandom();
        temp_addr = addr; 
        OP = 0; // fix it write operation !
      end
    end 
  endtask
endclass

class apb_error_condition extends apb_sequence;
   `uvm_object_utils(apb_error_condition)
  bit OP;
  int count;
  bit slave_select;
  function new(string name = "apb_error_condition");
    super.new(name);
  endfunction
  
  task body();
    repeat(50) begin
      req = apb_sequence_item::type_id::create("req");
      wait_for_grant();
       void'(req.randomize() with {req.READ_WRITE == OP; req.apb_write_paddr[`ADDR_WIDTH-1] ==slave_select ;req.apb_read_paddr[`ADDR_WIDTH-1] ==slave_select ;req.transfer == 1;} ); // const slave with toggling transfer for every 2nd operation !!
      req.apb_write_paddr =8'bxxxxxxxx;
      req.apb_read_paddr = 8'bxxxxxxxx;
      req.apb_write_data = 8'bxxxxxxxx;
       send_request(req);
      wait_for_item_done();
      OP = ~OP; // write read conti....
      count++;
      if(count == 2)begin
          count = 0;
          slave_select = ~slave_select;
      end
    end 
  endtask 
endclass

class error_write extends apb_sequence;
 `uvm_object_utils(error_write)

  function new(string name ="error_write");
    super.new(name);
  endfunction: new

 task body();
  repeat(50) begin
    req = apb_sequence_item::type_id::create("req");
    start_item(req);
    req.randomize()with{req.READ_WRITE == 0; req.transfer == 1;};
    req.apb_write_paddr = 9'bxxxxxxxxx;
    req.apb_write_data = 8'bxxxxxxxx;
    finish_item(req);
    req = apb_sequence_item::type_id::create("req");
    start_item(req);
    req.randomize()with{req.READ_WRITE == 1; req.transfer == 1;};
    req.apb_read_paddr = 9'bxxxxxxxxx;
    finish_item(req);
  end
 endtask: body
endclass: error_write 

class apb_regression_seq extends apb_sequence;
  apb_sequence seq_rnd;
  apb_sequence_write_read seq1;
  apb_sequence_different_slave seq2;
  apb_sequence_transfer_t seq3;
  apb_continuous_write_read seq4;
  apb_error_condition seq5;
  error_write seq6;
  `uvm_object_utils(apb_regression_seq)
  
  function new(string name = "apb_regression_seq");
        super.new(name);
    endfunction
  
  virtual task body();
    `uvm_do(seq5)
    `uvm_do(seq_rnd)
    `uvm_do(seq1)
    `uvm_do(seq2)
    `uvm_do(seq3)
    `uvm_do(seq4)
   // `uvm_do(seq6)
   // `uvm_do(seq5)
  endtask
  
endclass
