# encoding: UTF-8
require 'json'
require 'net/http'
require 'active_support'
require 'active_support/core_ext'

module GithubHelper

  GITHUB_API_URL = 'https://api.github.com'
  GITHUB_RAW_URL = 'https://raw.githubusercontent.com'
  GITHUB_REPO_NAME = 'D4UDigitalPlatform/CustomerFirstSFDC'
  GH_EOL='\n'

  def add_comments_from_deploy_result(gh_options, deploy_result, ghprbPullId, pre_comment)
    result={}
    missing_md_path = File.join(File.expand_path('../../../', __FILE__),'missing_md.json')
    if File.exist?(missing_md_path)
      puts "### missing_md_path Found: #{missing_md_path}"
      # get missing metadata api from project
      result[:missing_mds] = build_missing_md(missing_md_path)
      #puts result[:missing_mds]      
    else
      puts "### missing_md_path NOT Found: #{missing_md_path}"
      puts "### parsing deployment result file #{deploy_result}"

      if File.exist?(deploy_result)
        deploy_result_h = parse_json_content_to_hash(File.open(deploy_result, "r") { |f| f.read })
        # symbolize hash keys
        deploy_result_h = deploy_result_h.deep_symbolize_keys
        
        status = deploy_result_h.dig(:status)
        
        if status != 0
          # get summary
          # "BUILD_NUMBER: #{ENV['BUILD_NUMBER']}"
          # "message": "The metadata deploy operation failed.",
          result[:summary_text] = build_summary(deploy_result_h)
          #puts result[:summary_text]
          
          # get component Failures
          comp_failures_h = deploy_result_h.dig(:result,:details,:componentFailures)
          result[:comp_failures] = build_component_failures(comp_failures_h)
          #puts comp_failures
          
          # get test failures
          test_failures_h = deploy_result_h.dig(:result,:details,:runTestResult,:failures)
          result[:test_failures] = build_test_failures(test_failures_h)
          #puts test_failures

           # get code coverage warning
          cc_warnings_h = deploy_result_h.dig(:result,:details,:runTestResult,:codeCoverageWarnings)
          result[:cc_warnings] = build_coverage_warning(cc_warnings_h)
          #puts cc_warnings
        else
          puts "###### Deploy Success"  
        end

      else
        puts "###### No deploy result found in #{deploy_result}"
      end

    end

    if !result.blank?
      # build comment
      comment_body = build_comment(pre_comment, result)
      # post the comment
      post_comment(gh_options, ghprbPullId, comment_body)
    end

  end

  def build_comment(pre_comment, result)#, summary_text, missing_mds, comp_failures, test_failures,cc_warnings)
    str=''
    if !result[:summary_text].blank?
      str="#{str}#{GH_EOL}#{result[:summary_text]}#{GH_EOL}"
    end
    if !result[:missing_mds].blank?
      str="#{str}**MISSING METADATA FILES:**#{GH_EOL}"
      str="#{str}The following components are listed in manifest/package.xml and not found in metadata source folder#{GH_EOL}"
      str="#{str}```#{GH_EOL}#{result[:missing_mds]}```#{GH_EOL}"
      str="#{str}Please retrieve those components from dev sandbox and commit again.#{GH_EOL}"
    end
    if !result[:comp_failures].blank?
      str="#{str}**COMPONENT FAILURES:**#{GH_EOL}"
      str="#{str}```#{GH_EOL}#{result[:comp_failures]}```#{GH_EOL}"
    end
    if !result[:cc_warnings].blank?
      str="#{str}**CODE COVERAGE WARNING:**#{GH_EOL}"
      str="#{str}```#{GH_EOL}#{result[:cc_warnings]}```#{GH_EOL}"
    end
    if !result[:test_failures].blank?
      str="#{str}**TEST FAILURES:**#{GH_EOL}"
      str="#{str}```#{GH_EOL}#{result[:test_failures]}```#{GH_EOL}"
    end
    "{\"body\": \"#{pre_comment.gsub('"','\"')}#{GH_EOL}#{str.gsub('"','\"')}\"}"
  end

  def build_missing_md(missing_md_path)
    file_content = File.open(missing_md_path, "r") { |f| f.read }
    file_content_a= JSON.parse(file_content).try(:to_a)
    str=''
    file_content_a.each do |miss_item|
      str="#{str}- #{miss_item}#{GH_EOL}"
    end
    str
  end

  def build_summary(deploy_result_h)
    result= deploy_result_h.dig(:result)
    return nil if result.blank?
    str=''
    txtsize=16
    str="#{str}**#{result[:errorMessage]}**#{GH_EOL}" if !result[:errorMessage].blank?
    str="#{str}**#{deploy_result_h[:message]}**#{GH_EOL}" if !deploy_result_h[:message].blank?
    str="#{str}```#{GH_EOL}#{"JobId".ljust(txtsize)}: #{result[:id]}#{GH_EOL}"
    str="#{str}#{"Created Date".ljust(txtsize)}: #{convert_date(result[:createdDate])}#{GH_EOL}"
    str="#{str}#{"Start Date".ljust(txtsize)}: #{convert_date(result[:startDate])}#{GH_EOL}"
    str="#{str}#{"Completed Date".ljust(txtsize)}: #{convert_date(result[:completedDate])}#{GH_EOL}"
    str="#{str}#{"Component Errors".ljust(txtsize)}: #{result[:numberComponentErrors]}/#{result[:numberComponentsTotal]}#{GH_EOL}"
    str="#{str}#{"Test Errors".ljust(txtsize)}: #{result[:numberTestErrors]}/#{result[:numberTestsTotal]}#{GH_EOL}```#{GH_EOL}"
    str
  end

  def convert_date(str)
    my_tz='Paris'
    return nil if str.blank?
    DateTime.parse(str).in_time_zone(my_tz).to_s
  end

  def build_coverage_warning(cc_warnings_h)
    return nil if cc_warnings_h.blank?
    str=''
    [cc_warnings_h].flatten.each do |item|
      # TODO take in account Namespaces
      str="#{str}- #{item[:name]}: #{item[:message].gsub('\n','\\n')}#{GH_EOL}#{GH_EOL}"
    end
    str
  end

  def build_component_failures(comp_failures_h)
    return nil if comp_failures_h.blank?
    str=''
    [comp_failures_h].flatten.each do |item|
      # TODO take in account Namespaces
      # namespace=item.dig(:$)namespace
      linenumber = item[:lineNumber] ? "(Line: #{item[:lineNumber]})" : nil
      str="#{str}- #{item[:componentType]}: #{item[:fullName]} #{linenumber}#{GH_EOL}"
      str="#{str}#{item[:problemType]}: #{item[:problem].gsub(/\n/,'\n')}#{GH_EOL}#{GH_EOL}"
    end
    str
  end

  def build_test_failures(test_failures_h)
    return nil if test_failures_h.blank?
    str=''
    [test_failures_h].flatten.each do |item|
      # TODO take in account Namespaces
      # namespace=item.dig(:$)namespace
      str="#{str}- #{item[:name]}.#{item[:methodName]}: #{item[:message].gsub(/\n/,'\n')}#{GH_EOL}"
      #str="#{str}Stack Trace:#{GH_EOL}"
      str="#{str}#{item[:stackTrace].gsub(/\n/,'\n')}#{GH_EOL}#{GH_EOL}"
    end
    str
  end

  def post_comment(gh_options, ghprbPullId, comment_body)
    #comment_body= comment_body.gsub('\n','\\n')
    endpoint="#{GITHUB_API_URL}/repos/#{GITHUB_REPO_NAME}/issues/#{ghprbPullId}/comments"
    tmp_comment_body_path=File.join(File.expand_path('../../', __FILE__),"comment_body#{ghprbPullId}.json")
    save_file(tmp_comment_body_path, comment_body) 
    gh_post_cmd="curl -H 'Accept: application/json' -u #{gh_options[:username]}:#{gh_options[:password]} -X POST -d @'#{tmp_comment_body_path}' #{endpoint}"
    puts "Running cmd: #{gh_post_cmd}"
    puts `#{gh_post_cmd}`
    `rm -rf #{tmp_comment_body_path}`
    #puts "###### Comment on Pull request ##{ghprbPullId} was successfully created"
  end

  def get_issues_by_label label
    url = "issues?labels=#{label}"
    resp = github_request(:get, url, nil)
    resp.size
  end

  def  select_min_label ci_sandboxes
    label_count={}
    ci_sandboxes.each do |label|
      label_count[label] = get_issues_by_label(label)
    end
    puts "Nb issues by label #{label_count}"
    min_label_h=[label_count.min_by{|k, v| v}].to_h
    min_label_h.keys.first
  end

  def add_issue_label selectedLabel, ghprbPullId
    url = "issues/#{ghprbPullId}/labels"
    resp = github_request(:post, url, {"labels" => [selectedLabel]} )
    puts "#{selectedLabel} was successfully added to the PullRequest ##{ghprbPullId})" if !resp.blank?
  end

  def get_pr pr_number, info=nil, params=nil
    url = "pulls/#{pr_number}"
    url = "#{url}/#{info}" if info
    url = "#{url}?#{params.to_query}" if params
    github_request(:get, url, nil)
  end

  def get_pr_changed_files(pr_number, per_page=1000)
    pr_files = get_pr(pr_number, 'files', {per_page: per_page})
    pr_files.map{|file| file['filename']}
  end

  def update_commit_status sha, body
    resp = github_request(:post, "statuses/#{sha}", body )
    puts "Status on commit #{sha.first(7)} was successfully updated" if !resp.blank?
  end

  def get_last_reviewer_state(pr_reviews)
    # build a hash to get the last review state for each reviews
    # {"gh_user1"=>"CHANGES_REQUESTED", "gh_user2"=>"APPROVED", "gh_user3"=>"APPROVED"}
    last_review_by_reviewer = {}
    pr_reviews.each{ |rev|  last_review_by_reviewer[rev['user']['login']]=rev['state'] }
    # build map like
    # {"CHANGES_REQUESTED"=>["gh_user1"], "APPROVED"=>["gh_user2", "gh_user3"]}
    reviews_by_state = {}
    last_review_by_reviewer.each do |k,v|
      reviews_by_state[v] ||= []
      reviews_by_state[v] << k
    end
    return reviews_by_state
  end

  # CHECK AT LEAST ONE RM HAS APPROVE
  def check_RM_approvals(reviewers_states, rm_team)
    is_rm_approve = !reviewers_states['APPROVED'].blank? && reviewers_states['APPROVED'].any? { |login| rm_team.include?(login) }
    #puts "#### check_RM_approvals:is_rm_approve:#{is_rm_approve}"
    is_rm_pending_ch_req = !reviewers_states['CHANGES_REQUESTED'].blank? && reviewers_states['CHANGES_REQUESTED'].any? { |login| rm_team.include?(login) }
    #puts "#### check_RM_approvals:is_rm_pending_ch_req:#{is_rm_pending_ch_req}"
    return is_rm_approve && !is_rm_pending_ch_req
  end

  # CHECK AT LEAST ONE LEAD HAS APPROVE except RM
  def check_Lead_dev_approvals_no_rm_team(reviewers_states)
    is_lead_dev_approve = (reviewers_states['APPROVED'] || []).size > 0
    #puts "#### check_Lead_dev_approvals:is_lead_dev_approve:#{is_lead_dev_approve}"
    is_lead_dev_pending_ch_req = (reviewers_states['CHANGES_REQUESTED'] || []).size > 0
    #puts "#### check_Lead_dev_approvals:is_lead_dev_pending_ch_req:#{is_lead_dev_pending_ch_req}"
    return is_lead_dev_approve && !is_lead_dev_pending_ch_req
  end

  # CHECK AT LEAST ONE LEAD HAS APPROVE
  def check_Lead_dev_approvals(reviewers_states, rm_team)
    is_lead_dev_approve = ((reviewers_states['APPROVED'] || []) - rm_team).size > 0
    #puts "#### check_Lead_dev_approvals:is_lead_dev_approve:#{is_lead_dev_approve}"
    is_lead_dev_pending_ch_req = ((reviewers_states['CHANGES_REQUESTED'] || []) - rm_team).size > 0
    #puts "#### check_Lead_dev_approvals:is_lead_dev_pending_ch_req:#{is_lead_dev_pending_ch_req}"
    return is_lead_dev_approve && !is_lead_dev_pending_ch_req
  end

  # CHECK NO more LEAD DEV REVIEW REQUEST exceptt RM
  def check_no_more_lead_dev_approvals_no_rm_team(requested_reviewers)
    requested_reviewers_logins = requested_reviewers.map { |r| r['login'] }
    #puts "#### check_no_more_lead_dev_approvals:requested_reviewers_logins:#{requested_reviewers_logins}"
    return requested_reviewers_logins.size == 0
  end

  # CHECK NO more LEAD DEV REVIEW REQUEST
  def check_no_more_lead_dev_approvals(requested_reviewers, rm_team)
    requested_reviewers_logins = requested_reviewers.map { |r| r['login'] }
    #puts "#### check_no_more_lead_dev_approvals:requested_reviewers_logins:#{requested_reviewers_logins}"
    return (requested_reviewers_logins - rm_team).size == 0
  end

  def github_request(method, url, body=nil)
    uri = URI.parse("#{GITHUB_API_URL}/repos/#{GITHUB_REPO_NAME}/#{url}")
    request = "Net::HTTP::#{method.to_s.camelize}".constantize.new(uri)
    request.basic_auth(@ghUsername, @ghPassword)
    request["Accept"] = "application/json"
    req_options = {
      use_ssl: uri.scheme == "https",
    }
    if body
      request.body = JSON.dump(body)
    end
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    if response.kind_of? Net::HTTPSuccess
      JSON.parse(response.body)
    else
      puts "###### response.code: #{response.code}"
      puts "###### response.body: #{response.body}"
      raise "#{response.code} - #{response.message}"
    end
  end

  def github_get_raw_file(commit_sha, file_name)
    uri = URI.parse("#{GITHUB_RAW_URL}/#{GITHUB_REPO_NAME}/#{commit_sha}/#{file_name}")
    request = Net::HTTP::Get.new(uri)
    request.basic_auth(@ghUsername, @ghPassword)
    request["Accept"] = "application/vnd.github.v3.raw"
    req_options = {
        use_ssl: uri.scheme == "https",
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    if response.kind_of? Net::HTTPSuccess
      response.body
    else
      puts "###### response.code: #{response.code}"
      puts "###### response.body: #{response.body}"
      raise "#{response.code} - #{response.message}"
    end
  end

  def extract_jira_numbers(description)
    jira_nbs = description.scan(/JIRA_NUMBERS:\s\[(.*?)\]/).flatten.first
    (jira_nbs.blank?)? nil : jira_nbs.split(',') 
  end
  
end
