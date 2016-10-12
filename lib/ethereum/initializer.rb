module Ethereum

  class Initializer
    attr_accessor :contracts, :file, :client

    def initialize(client = Ethereum::IpcClient.new)
      @client = client
    end

    def use_solidity(file)
      @file = File.read(file)
      @contracts = compile_solidity
    end

    def use_compiled(file)
      @file = File.read(file)
      @contracts = parse_file
    end

    def build_all
      @contracts.each do |contract|
        contract.build(@client)
      end
    end

    private

    def parse_file
      src = JSON.parse(@file)
      src["contracts"].map do |name,con|
        Ethereum::Contract.new name, con["bin"], con["abi"]
      end
    end

    def compile_solidity
      resp = @client.compile_solidity(@file)
      raise "Error compiling solidity file: #{resp["error"]["message"]}" if resp["error"]
      contract_names = resp["result"].keys
      contract_names.map do |name|
        abi = resp["result"][name]["info"]["abiDefinition"]
        code = resp["result"][name]["code"]
        Ethereum::Contract.new(name, code, abi)
      end
    end
  end
end
