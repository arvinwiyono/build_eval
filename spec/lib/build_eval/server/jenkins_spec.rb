describe BuildEval::Server::Jenkins do

  let(:uri) { "https://dev-idam-jenkins.cse.dev.myob.com" }
  let(:username) { "some_username" }
  let(:password) { "some_password" }

  let(:jenkins) { described_class.new(uri: uri, username: username, password: password) }

  describe "#build_result" do

    let(:build_name)       { "some_build_name" }
    let(:response_code)    { nil }
    let(:response_message) { nil }
    let(:response_body)    { nil }
    
    let(:response) do
      instance_double(Net::HTTPResponse, code: response_code, message: response_message, body: response_body)
    end

    subject { jenkins.build_result(build_name) }

    before(:example) { allow(BuildEval::Http).to receive(:get).and_return(response) }

    it "issues a get request for the build" do
      expected_uri = "#{uri}/api/xml"
      expect(BuildEval::Http).to receive(:get).with(expected_uri, hash_including(username: username, password: password))

      subject rescue Exception
    end

    context "when the server responds with build results" do

      let(:response_code)       { "200" }
      let(:response_message)    { "OK" }
      let(:latest_build_status) { "red" }
      let(:response_body) do
        <<-RESPONSE
          <hudson>
            <assignedLabel/>
            <mode>EXCLUSIVE</mode>
            <nodeDescription>the master Jenkins node</nodeDescription>
            <nodeName/>
            <numExecutors>1</numExecutors>
            <job>
              <name>#{build_name}</name>
              <url>#{uri}/job/identityserver_performance_testing/</url>
              <color>#{latest_build_status}</color>
            </job>
            <job>
              <name>Jenkins Backup</name>
              <url>https://dev-idam-jenkins.cse.dev.myob.com/job/Jenkins%20Backup/</url>
              <color>blue</color>
            </job>
          </hudson>
        RESPONSE
      end

      it "creates a build result containing the build name" do
        expect(BuildEval::Result::BuildResult).to receive(:create).with(hash_including(build_name: build_name))
        subject
      end

      it "creates a build result containing the latest build status" do
        expect(BuildEval::Result::BuildResult).to receive(:create).with(hash_including(status_name: "Failure"))
        subject
      end

      it "returns the created result" do
        build_result = instance_double(BuildEval::Result::BuildResult)
        allow(BuildEval::Result::BuildResult).to receive(:create).and_return(build_result)

        expect(subject).to eql(build_result)
      end
    end

    context "when the build is not found" do

      let(:response_code)    { "404" }
      let(:response_message) { "Not Found" }
      let(:response_body)    { { "file" => "not found" }.to_json }

      it "raises an error" do
        expect { subject }.to raise_error(/Not Found/)
      end
    end
  end

  describe "#to_s" do

    subject { jenkins.to_s }

    it "returns a string indicating it uses the Jenkins CI service" do
      expect(subject).to include("Jenkins CI")
    end

    it "returns a string containing the username" do
      expect(subject).to include(uri)
    end

  end
end