module AwsSdkOperations
  def loop_until_finished(client, method, params = {})
    loop do
      response = client.send(method, params)
      yield(response)
      break if !response.respond_to?(:next_token) || response[:next_token].nil?
      params[:next_token] = response[:next_token]
    end
  end
end
