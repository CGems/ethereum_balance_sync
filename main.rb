require 'eth_tool'
require 'mysql2'

EthTool.rpc = "https://mainnet.infura.io/gQaYXSetjNSMUyJ9IMDv"
EthTool.logger = Logger.new(STDOUT)

tokens = {
  sda: {
    id: 18,
    contract: '0x4212fea9fec90236ecc51e41e2096b16ceb84555',
    decimals: 18
  }
}
# sda
# token_contract_address = '0x4212fea9fec90236ecc51e41e2096b16ceb84555'
# token_decimals = 18

# # icx
# token_contract_address = '0xb5a5f22694352c15b00323844ad545abb2b11028'
# token_decimals = 18

# eos
# token_contract_address = '0x86fa049857e0209aa7d9e616f7eb3b3b78ecfdb0'
# token_decimals = 18

# moac
# token_contract_address = '0xCBcE61316759D807c474441952cE41985bBC5a40'
# token_decimals = 18

# gve
# token_contract_address = '0x81705082ef9f0d660f07be80093d46d826d48b25'
# token_decimals = 18

def update_token_balances(client, addresses, token_id, token_contract, token_decimals)
  addresses.each do |address|
    token_balance = EthTool.get_token_balance(address, token_contract, token_decimals)
    sql = "update payment_addresses set balance=#{token_balance} where currency=#{token_id} and address='#{address}'"
    puts sql
    client.query sql
  end
rescue => ex
  puts ex.message
end

def list_eth(addresses)
  addresses.each do |address|
    eth_balance = EthTool.get_eth_balance(address)
    wputs "#{address}: #{eth_balance}"
  end
end

def get_addresses_by_token client, token_id
  results = client.query("select distinct(address) from payment_transactions where aasm_state='confirmed' and txid in (select txid from deposits where currency=#{token_id} and aasm_state='accepted' and txid is not null and length(txid)=66)")
  results.map do |row| row["address"] end
end

client = Mysql2::Client.new(:host => "localhost", :port => "3306", :username => "root", :password => '123456', :database => 'peatio_development')
tokens.each_pair do |token_symbol, token|
  addresses = get_addresses_by_token client, token[:id]
  update_token_balances(client, addresses, token[:id], token[:contract], token[:decimals])
end
