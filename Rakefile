# encoding: UTF-8
require 'json'
require 'net/http'
require 'active_support'
require 'active_support/core_ext'

module GithubHelper

  GITHUB_API_URL = 'https://api.github.com'
  GITHUB_RAW_URL = 'https://raw.githubusercontent.com'
  GITHUB_REPO_NAME = 'therajwala/pipelines-java'
  GH_EOL='\n'

  

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

  



  # CHECK AT LEAST ONE LEAD HAS APPROVE
  def check_Lead_dev_approvals(reviewers_states, rm_team)
    is_lead_dev_approve = ((reviewers_states['APPROVED'] || []) - rm_team).size > 0
    #puts "#### check_Lead_dev_approvals:is_lead_dev_approve:#{is_lead_dev_approve}"
    is_lead_dev_pending_ch_req = ((reviewers_states['CHANGES_REQUESTED'] || []) - rm_team).size > 0
    #puts "#### check_Lead_dev_approvals:is_lead_dev_pending_ch_req:#{is_lead_dev_pending_ch_req}"
    return is_lead_dev_approve && !is_lead_dev_pending_ch_req
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

# rake github:check_pr_approval[ghUsername,ghPassword]
  desc "Check PR approval"
  task :check_pr_approval, [:ghUsername, :ghPassword, :pr_number] do |task, args|
    puts "STARTING TASK: #{task}"
    puts "WITH ARGS #{args}"

    # check the REQUIRED CLI ARGUMENTS
    puts "ERROR: 'pr_number' argument is required !" if args[:pr_number].blank?
    raise "Usage:  rake github:check_pr_approval[ghUsername,ghPassword,]" if args[:pr_number].blank?


    # CLI arguments
    @ghUsername = args[:ghUsername]
    @ghPassword = args[:ghPassword]
    pr_number  = args[:pr_number]
   

    

      # 0 retrieve PR and extract Jira Numbers
      pr = get_pr(pr_number)
      #puts "################ PR: #{pr.to_json}"
      

      

 

      ## 3 CHECK PR APPROVALS
      pr_reviews = get_pr(pr_number, 'reviews', {per_page: 100})
      #puts "################ pr_reviews: #{pr_reviews.to_json}"
      reviewers_states = get_last_reviewer_state(pr_reviews)
      #puts "################ reviewers_states: #{reviewers_states.to_json}"

      # CHECK AT LEAST ONE LEAD HAS APPROVE
      is_approved_lead_dev = check_Lead_dev_approvals(reviewers_states, rm_team)

      # CHECK NO more LEAD DEV REVIEW REQUEST
      is_no_pending_approvals = check_no_more_lead_dev_approvals(pr['requested_reviewers'], rm_team)
      puts "##-- is_no_pending_approvals:#{is_no_pending_approvals}"
      puts "##-- is_approved_lead_dev:#{is_approved_lead_dev}"
      is_pr_approved = is_no_pending_approvals && is_approved_lead_dev
      if is_pr_approved
        puts "CHECK 3/3: PASS - PR was successfully approved by lead dev"
      else
        msg = "FAIL: Missing approval from Lead Dev!\nPlease approve it and open and close this PR to relaunch validation"
        check_errors << msg
        puts "CHECK 3/3: #{msg}"
      end


    rescue Exception => e 
      check_errors << e.message
      puts "check_errors:#{check_errors}\n (#{e.message}) \n#{e.backtrace.join("\n\t")}"
    end

    status_body = if check_errors.blank?
      {
        state: 'success',  #Required. The state of the status. Can be one of error, failure, pending, or success.
        target_url: "#{ENV['BUILD_URL']}console",
        description: 'Pass',
        context: CHECK_CONTEXT
      }
    else
      {
        state: 'failure',
        target_url: "#{ENV['BUILD_URL']}console",
        description: check_errors.join(' ; ').truncate(140),
        context: CHECK_CONTEXT
        }
    end
    update_commit_status(pr['head']['sha'], status_body)
    if check_errors.blank?
      puts "All checks succeeded :-)"
    else
      raise "PR Checks failed #{check_errors.join('\n')}"
    end
  
