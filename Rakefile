# encoding: UTF-8
require 'pathname'
require 'fileutils'
require_relative 'lib/metadata_helper'
include MetadataHelper
require_relative 'lib/jira_helper'
include JiraHelper
require_relative 'lib/scripts_helper'
include ScriptsHelper
require_relative 'lib/github_helper'
include GithubHelper
require_relative 'lib/md_manifest_helper'
include MdManifestHelper
require_relative 'lib/manifest'
require_relative 'lib/custom_labels'
#include CustomLabels
require_relative 'lib/md_custom_labels_helper'
include MdCustomLabelsHelper
require_relative 'lib/email/email_sender'

include FileUtils


DEBUG = ENV['DEBUG']=="1" || false
SCRIPTS_ROOT = File.dirname(__FILE__)
PROJECT_ROOT = File.expand_path('..',File.dirname(__FILE__))
JIRA_URL = 'https://jira-it1.mpsa.com/'
#task default: %w[filter_metadata]

namespace :metadata do
  # rake metadata:filter_by_package[]
  # BUNDLE_GEMFILE="./scripts/Gemfile" rake metadata:filter_by_package['src','classic','manifest/package.xml','filtred-metadata']
  desc "Filter metadata source folder from package.xml content."
  task :filter_by_package, [:input_folder, :input_format, :package_xml, :destructiveChanges_xml, :output_folder, :filter_profiles] do |task, args|
    # args={}
    #input_folder = args[:input_folder] || 'force-app/main/default' 
    input_folder = args[:input_folder] || 'test/src' 
    input_format = args[:input_format] || 'sfdx'
    package_xml = args[:package_xml] || 'test/manifest/package.xml'
    destructiveChanges_xml = args[:destructiveChanges_xml] || 'test/manifest/destructiveChanges.xml'
    output_folder = args[:output_folder] || 'filtred-metadata'
    filter_profiles = (!args[:filter_profiles].blank? && args[:filter_profiles] == 'true') ? true : false
    puts "STARTING", args
    filter_metadata(package_xml, destructiveChanges_xml, input_folder, input_format, output_folder, filter_profiles)
  end

  # rake metadata:validate[]
  # rake metadata:validate['test/force-app/main/default','sfdx','test/manifest/package.xml']
  # rake metadata:validate['test/src','classic','test/manifest/package.xml']
  # BUNDLE_GEMFILE="./scripts/Gemfile" bundle exec rake metadata:validate['force-app/main/default','sfdx','manifest/package.xml']
  desc "Filter metadata source folder from package.xml content."
  task :validate, [:input_folder, :input_format, :package_xml] do |task, args|
    # args={}
    input_folder = args[:input_folder] || 'test/force-app/main/default' 
    input_format = args[:input_format] || 'sfdx'
    package_xml = args[:package_xml] || 'test/manifest/package.xml'
    puts "STARTING", args
    validate_metadata(package_xml, input_folder, input_format)
  end

  # BUNDLE_GEMFILE="./scripts/Gemfile" rake metadata:test_needed[1234,gh_username,gh_password] -f ./scripts/Rakefile
  desc "Check if test needed "
  task :test_needed, [:pr_number, :gh_username, :gh_password] do |_, args|
    #puts "STARTING", args
    # check the REQUIRED CLI ARGUMENTS
    puts "ERROR: 'pr_number' argument is required !" if args[:pr_number].blank?
    puts "ERROR: 'gh_username' argument is required !" if args[:gh_username].blank?
    puts "ERROR: 'gh_password' argument is required !" if args[:gh_password].blank?
    if args[:pr_number].blank? || args[:gh_password].blank? || args[:gh_username].blank?
      raise <<-EOS
        This command check if the tests are needed to run from changes in the pull request. 
        Usage: 
          rake metadata:test_needed[1234,gh_username,gh_password]
      EOS
    end
    pr_number = args[:pr_number]
    @ghUsername = args[:gh_username]
    @ghPassword = args[:gh_password]

    pr_changed_files=get_pr_changed_files(pr_number)
    puts "######### pr_changed_files #{pr_changed_files}" if DEBUG

    test_required_files_changes = tests_needed_from_file_names(pr_changed_files)
    puts "######### test_required_files_changes #{test_required_files_changes}" if DEBUG

    if test_required_files_changes
      puts true
      exit(0)
    end

    puts "###### checking Manifest files changes ..." if DEBUG
    package_path="manifest/package.xml"
    destructive_path="manifest/destructiveChanges.xml"
    pr = get_pr(pr_number)
    head_commit_sha = pr['head']['sha']
    #`git fetch &> /dev/null`
    #merge_commit_sha= `git merge-base origin/#{pr['base']['ref']} origin/#{pr['head']['ref']}`.chomp
    merge_commit_sha= pr['merge_commit_sha']
    base_commit_sha  = pr['base']['sha']
    if pr_changed_files.include?(package_path) || pr_changed_files.include?(destructive_path)
      res_package = tests_needed_from_manifest_changes(merge_commit_sha, head_commit_sha, base_commit_sha, package_path)
      puts "####### changed detected in manifest/package.xml. neeed to run test: #{res_package}" if DEBUG
      res_destructive = tests_needed_from_manifest_changes(merge_commit_sha, head_commit_sha, base_commit_sha, destructive_path)
      puts "####### changed detected in manifest/destructiveChanges.xml. neeed to run test: #{res_destructive}" if DEBUG
      puts res_package || res_destructive
    else
      puts false
    end

  end

  task :test_needed_for_package, [:pr_number, :gh_username, :gh_password, :package] do |_, args|
    #puts "STARTING", args
    # check the REQUIRED CLI ARGUMENTS
    puts "ERROR: 'pr_number' argument is required !" if args[:pr_number].blank?
    puts "ERROR: 'gh_username' argument is required !" if args[:gh_username].blank?
    puts "ERROR: 'gh_password' argument is required !" if args[:gh_password].blank?
    if args[:pr_number].blank? || args[:gh_password].blank? || args[:gh_username].blank?
      raise <<-EOS
        This command check if the tests are needed to run from changes in the pull request. 
        Usage: 
          rake metadata:test_needed[1234,gh_username,gh_password,package]
      EOS
    end
    pr_number = args[:pr_number]
    @ghUsername = args[:gh_username]
    @ghPassword = args[:gh_password]

    pr_changed_files=get_pr_changed_files(pr_number)
    puts "######### pr_changed_files #{pr_changed_files}" if DEBUG

    test_required_files_changes = tests_needed_from_file_names(pr_changed_files)
    puts "######### test_required_files_changes #{test_required_files_changes}" if DEBUG

    if test_required_files_changes
      puts true
      exit(0)
    end

    puts "###### checking Manifest files changes ..." if DEBUG
    # package_path="manifest/package.xml"
    package_path = args[:package]
    destructive_path="manifest/destructiveChanges.xml"
    pr = get_pr(pr_number)
    head_commit_sha = pr['head']['sha']
    #`git fetch &> /dev/null`
    #merge_commit_sha= `git merge-base origin/#{pr['base']['ref']} origin/#{pr['head']['ref']}`.chomp
    merge_commit_sha= pr['merge_commit_sha']
    base_commit_sha  = pr['base']['sha']
    if pr_changed_files.include?(package_path) || pr_changed_files.include?(destructive_path)
      res_package = tests_needed_from_manifest_changes(merge_commit_sha, head_commit_sha, base_commit_sha, package_path)
      puts "####### changed detected in manifest/package.xml. neeed to run test: #{res_package}" if DEBUG
      res_destructive = tests_needed_from_manifest_changes(merge_commit_sha, head_commit_sha, base_commit_sha, destructive_path)
      puts "####### changed detected in manifest/destructiveChanges.xml. neeed to run test: #{res_destructive}" if DEBUG
      puts res_package || res_destructive
    else
      puts false
    end

  end
end

namespace :jira do
  # rake jira:update_jira_issues[]
  # rake jira:update_issues['USERNAME','PASSWORKD','project = C1STAGILE AND fixVersion = R_3.1.1.0 AND assignee = e552564 AND labels not in (DEPLOYED_ETE)','labels','DEPLOYED_ETE','add']
  desc "Update Jira issues"
  task :update_jira_issues, [:username, :password, :jql, :field_to_update_name, :field_to_update_value, :operation] do |task, args|
    # args={}
    username = args[:username] || ''
    password = args[:password] || ''
    jql = args[:jql]  || ''
    field_to_update_name  = args[:field_to_update_name]  || 'labels'
    field_to_update_value  = args[:field_to_update_value]  || ''
    operation  = args[:operation]  || 'add'
    puts "STARTING", args
    
    # prepare jira credential
    jira_options = {
      :username     => username,
      :password     => password,
      :site         => JIRA_URL,
      :context_path => '',
      :auth_type    => :basic
    }
    update_jira_issues_from_JQL(jira_options, jql, field_to_update_name, field_to_update_value, operation)
  end

  # rake jira:update_jira_issues_field['USERNAME','PASSWORKD','id in (C1STDEPLOY-812,C1STAGILE-15522)','PR_CREATED','PR_CREATED;PR_APPROVED']
  desc "Update Jira issues field"
  task :update_jira_issues_field, [:username, :password, :jql, :field, :values_to_add, :values_to_remove] do |task, args|
    # args={}
    username = args[:username]
    password = args[:password]
    jql = args[:jql]  
    field = args[:field] 
    values_to_add  = args[:values_to_add]  || ''
    values_to_remove  = args[:values_to_remove]  || ''
    puts "STARTING", args
    
    # prepare jira credential
    jira_options = {
      :username     => username,
      :password     => password,
      :site         => JIRA_URL,
      :context_path => '',
      :auth_type    => :basic
    }
    update_jira_field_issues_from_JQL(jira_options, jql, field, values_to_add.split(';'), values_to_remove.split(';'))
  end

  # rake jira:create_comments[]
  # rake jira:add_jira_comments['ghUsername','ghPassword','project = C1STAGILE AND fixVersion = R_3.1.1.0 AND assignee = e552564 AND labels not in (DEPLOYED_ETE)','comment']
  desc "Add Jira comments"
  task :add_jira_comments, [:username, :password, :jql, :comment] do |task, args|
    # args={}
    username = args[:username] || ''
    password = args[:password] || ''
    jql = args[:jql]  || ''
    comment  = args[:comment] || nil
    puts "STARTING", args
    
    # prepare jira credential
    jira_options = {
      :username     => username,
      :password     => password,
      :site         => JIRA_URL,
      :context_path => '',
      :auth_type    => :basic
    }
    if !comment.blank?
      add_comments_from_JQL(jira_options, jql, comment)
    else
      puts "############## Empty Jira comment !"
    end
  end
end


namespace :github do
  # rake github:add_github_comment[ghUsername,ghPassword,../testCI11-0Af3E00000bJzYESA0.json,1221,'[![Build Status](https://jenkins.c1staws.awsmpsa.com/buildStatus/icon?job=Pull_Request_Builder_RELEASE_R_4.3.0.0-v2&build=87)](https://jenkins.c1staws.awsmpsa.com/job/Pull_Request_Builder_RELEASE_R_4.3.0.0-v2/87/console)']
  desc "Add Github comments"
  task :add_github_comment, [:username, :password, :deploy_result, :ghprbPullId, :comment] do |task, args|
    
    username = args[:username] || ''
    password = args[:password] || ''
    deploy_result = args[:deploy_result]  || ''
    comment  = args[:comment] || nil
    ghprbPullId  = args[:ghprbPullId] || nil
    puts "STARTING", args
    
    # prepare jira credential
    gh_options = {
      :username     => username,
      :password     => password
    }
    add_comments_from_deploy_result(gh_options, deploy_result, ghprbPullId, comment)
  end

   ######################################################################################################
  # rake github:check_pr_approval_for_develop[ghUsername,ghPassword,3346,jiraUsername,jiraPassword,R_D.4.1.0]
  desc "Check PR approval for DEVELOP branch"
  task :check_pr_approval_for_develop, [:ghUsername, :ghPassword, :pr_number, :jiraUsername, :jiraPassword, :affects_version] do |task, args|
    puts "STARTING TASK: #{task}"
    puts "WITH ARGS #{args}"

    # check the REQUIRED CLI ARGUMENTS
    puts "ERROR: 'pr_number' argument is required !" if args[:pr_number].blank?
    puts "ERROR: 'affects_version' argument is required !" if args[:affects_version].blank?
    raise "Usage:  rake github:check_pr_approval_for_develop[ghUsername,ghPassword,3346,jiraUsername,jiraPassword,R_D.4.1.0]" if args[:pr_number].blank? || args[:affects_version].blank?

    # Check the REQUIRED Arguments and env Variables
    if ENV['GITHUB_RM_TEAM'].blank?
      puts "ERROR: 'GITHUB_RM_TEAM' environment variable is not set !"
      exit(1)
    end
    # Check Optional Evn variables
    unless ENV['BUILD_URL']
      puts "WARNING: No var env BUILD_URL is empty, The check will not be linked to the ci build"
    end
    unless ENV['CHECK_CONTEXT']
      puts "WARNING: No var env CHECK_CONTEXT is empty. Use the default check context name 'Jenkins-PR-Check' "
    end
    CHECK_CONTEXT = ENV['CHECK_CONTEXT'] || 'Jenkins-PR-Check'

    # CLI arguments
    @ghUsername = args[:ghUsername]
    @ghPassword = args[:ghPassword]
    pr_number  = args[:pr_number]
    @jiraUsername = args[:jiraUsername]
    @jiraPassword = args[:jiraPassword]
    affects_version  = args[:affects_version]

    # Used environment variables
    puts "#### ENV['GITHUB_RM_TEAM']:#{ENV['GITHUB_RM_TEAM']}"
    rm_team = ENV['GITHUB_RM_TEAM'].split(";").uniq.compact
    # local variables
    check_errors = []

    # jira label status we are using
    labels_to_delete = [JiraHelper::JIRA_LABEL_PR_CREATED,
                        JiraHelper::JIRA_LABEL_PR_APPROVED,
                        JiraHelper::JIRA_LABEL_PR_FAILED,
                        JiraHelper::JIRA_LABEL_PR_VALIDATED]

    begin

      # prepare jira credential
      jira_options = {
        :username     => @jiraUsername,
        :password     => @jiraPassword,
        :site         => JIRA_URL,
        :context_path => '',
        :auth_type    => :basic
      }

      # 0 retrieve PR and extract Jira Numbers
      pr = get_pr(pr_number)
      #puts "################ PR: #{pr.to_json}"
      jira_nbs = extract_jira_numbers(pr['body'])


      ## 1 CHECK JIRA IN PR
      if !jira_nbs.blank?
        puts "CHECK 1/2: PASS - Successfully found Jira Number(s)."
      else
        error_msg = "FAIL: Missing Jira number!\nPlease add Jira Number(s) to the Pull Request description"
        check_errors << error_msg
        puts "CHECK 1/2: #{error_msg}"
      end 

      ## 2 CHECK Jir existence and 'Affects Version/s:'
      (jira_nbs || []).each do |jira_nb|
        begin
        # init Jira client
          client = JIRA::Client.new(jira_options)
          issue = client.Issue.find(jira_nb)
          # map the fields to easily access to them
          client.Field.map_fields
          affects_versions = issue.Affects_Version_s
          if affects_versions.map{|v| v['name']}.include?(affects_version)
            puts "CHECK 2/3: PASS - Successfully found Affects_Version_s in #{jira_nb} ." 
          else
            error_msg = "FAIL: Incorrect 'Affects Version/s' in #{jira_nb}."
            check_errors << error_msg
            puts "CHECK 2/3: #{error_msg}"
          end
        rescue Exception => e 
          raise "ERROR: Unable to access to Jira. Please check Jira credentials." if e.message == 'Unauthorized'
          error_msg = "FAIL: Unable to find #{jira_nb}."
          check_errors << error_msg
          puts "CHECK 2/3: #{error_msg} (#{e.message}) \n#{e.backtrace.join("\n\t")}"
        end
        #issue.Fix_Version_s
      end

      ## 3 CHECK PR APPROVALS
      pr_reviews = get_pr(pr_number, 'reviews', {per_page: 100})
      #puts "################ pr_reviews: #{pr_reviews.to_json}"
      reviewers_states = get_last_reviewer_state(pr_reviews)
      #puts "################ reviewers_states: #{reviewers_states.to_json}"
      # CHECK AT LEAST ONE RM HAS APPROVE
      # is_approved_rm = check_RM_approvals(reviewers_states, rm_team)

      # CHECK AT LEAST ONE LEAD HAS APPROVE
      is_approved_lead_dev = check_Lead_dev_approvals_no_rm_team(reviewers_states)

      # CHECK NO more LEAD DEV REVIEW REQUEST
      is_no_pending_approvals = check_no_more_lead_dev_approvals_no_rm_team(pr['requested_reviewers'])
      puts "##-- is_no_pending_approvals:#{is_no_pending_approvals}"
      # puts "##-- is_approved_rm:#{is_approved_rm}"
      puts "##-- is_approved_lead_dev:#{is_approved_lead_dev}"
      is_pr_approved = is_no_pending_approvals && is_approved_lead_dev
      if is_pr_approved
        puts "CHECK 3/3: PASS - PR was successfully approved by lead dev."
      else
        msg = "FAIL: Missing approval from Lead Dev!\nPlease approve it and open and close this PR to relaunch validation"
        check_errors << msg
        puts "CHECK 3/3: #{msg}"
      end

      if !jira_nbs.blank?
        update_jira_field_issues_from_JQL(jira_options,
                                          "id in (#{jira_nbs.join(',')})",
                                          'labels',
                                          [ (is_pr_approved)? JiraHelper::JIRA_LABEL_PR_APPROVED : JiraHelper::JIRA_LABEL_PR_CREATED],
                                          labels_to_delete)
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
  end

  ######################################################################################################
  # rake github:check_pr_approval[ghUsername,ghPassword,3346,jiraUsername,jiraPassword,R_D.4.1.0]
  desc "Check PR approval"
  task :check_pr_approval, [:ghUsername, :ghPassword, :pr_number, :jiraUsername, :jiraPassword, :affects_version] do |task, args|
    puts "STARTING TASK: #{task}"
    puts "WITH ARGS #{args}"

    # check the REQUIRED CLI ARGUMENTS
    puts "ERROR: 'pr_number' argument is required !" if args[:pr_number].blank?
    puts "ERROR: 'affects_version' argument is required !" if args[:affects_version].blank?
    raise "Usage:  rake github:check_pr_approval[ghUsername,ghPassword,3346,jiraUsername,jiraPassword,R_D.4.1.0]" if args[:pr_number].blank? || args[:affects_version].blank?

    # Check the REQUIRED Arguments and env Variables
    if ENV['GITHUB_RM_TEAM'].blank?
      puts "ERROR: 'GITHUB_RM_TEAM' environment variable is not set !"
      exit(1)
    end
    # Check Optional Evn variables
    unless ENV['BUILD_URL']
      puts "WARNING: No var env BUILD_URL is empty, The check will not be linked to the ci build"
    end
    unless ENV['CHECK_CONTEXT']
      puts "WARNING: No var env CHECK_CONTEXT is empty. Use the default check context name 'Jenkins-PR-Check' "
    end
    CHECK_CONTEXT = ENV['CHECK_CONTEXT'] || 'Jenkins-PR-Check'

    # CLI arguments
    @ghUsername = args[:ghUsername]
    @ghPassword = args[:ghPassword]
    pr_number  = args[:pr_number]
    @jiraUsername = args[:jiraUsername]
    @jiraPassword = args[:jiraPassword]
    affects_version  = args[:affects_version]

    # Used environment variables
    puts "#### ENV['GITHUB_RM_TEAM']:#{ENV['GITHUB_RM_TEAM']}"
    rm_team = ENV['GITHUB_RM_TEAM'].split(";").uniq.compact
    # local variables
    check_errors = []

    # jira label status we are using
    labels_to_delete = [JiraHelper::JIRA_LABEL_PR_CREATED,
                        JiraHelper::JIRA_LABEL_PR_APPROVED,
                        JiraHelper::JIRA_LABEL_PR_FAILED,
                        JiraHelper::JIRA_LABEL_PR_VALIDATED]

    begin

      # prepare jira credential
      jira_options = {
        :username     => @jiraUsername,
        :password     => @jiraPassword,
        :site         => JIRA_URL,
        :context_path => '',
        :auth_type    => :basic
      }

      # 0 retrieve PR and extract Jira Numbers
      pr = get_pr(pr_number)
      #puts "################ PR: #{pr.to_json}"
      jira_nbs = extract_jira_numbers(pr['body'])


      ## 1 CHECK JIRA IN PR
      if !jira_nbs.blank?
        puts "CHECK 1/2: PASS - Successfully found Jira Number(s)."
      else
        error_msg = "FAIL: Missing Jira number!\nPlease add Jira Number(s) to the Pull Request description"
        check_errors << error_msg
        puts "CHECK 1/2: #{error_msg}"
      end 

      ## 2 CHECK Jir existence and 'Affects Version/s:'
      (jira_nbs || []).each do |jira_nb|
        begin
        # init Jira client
          client = JIRA::Client.new(jira_options)
          issue = client.Issue.find(jira_nb)
          # map the fields to easily access to them
          client.Field.map_fields
          affects_versions = issue.Affects_Version_s
          if affects_versions.map{|v| v['name']}.include?(affects_version)
            puts "CHECK 2/3: PASS - Successfully found Affects_Version_s in #{jira_nb} ." 
          else
            error_msg = "FAIL: Incorrect 'Affects Version/s' in #{jira_nb}."
            check_errors << error_msg
            puts "CHECK 2/3: #{error_msg}"
          end
        rescue Exception => e 
          raise "ERROR: Unable to access to Jira. Please check Jira credentials." if e.message == 'Unauthorized'
          error_msg = "FAIL: Unable to find #{jira_nb}."
          check_errors << error_msg
          puts "CHECK 2/3: #{error_msg} (#{e.message}) \n#{e.backtrace.join("\n\t")}"
        end
        #issue.Fix_Version_s
      end

      ## 3 CHECK PR APPROVALS
      pr_reviews = get_pr(pr_number, 'reviews', {per_page: 100})
      #puts "################ pr_reviews: #{pr_reviews.to_json}"
      reviewers_states = get_last_reviewer_state(pr_reviews)
      #puts "################ reviewers_states: #{reviewers_states.to_json}"
      # CHECK AT LEAST ONE RM HAS APPROVE
      is_approved_rm = check_RM_approvals(reviewers_states, rm_team)

      # CHECK AT LEAST ONE LEAD HAS APPROVE
      is_approved_lead_dev = check_Lead_dev_approvals(reviewers_states, rm_team)

      # CHECK NO more LEAD DEV REVIEW REQUEST
      is_no_pending_approvals = check_no_more_lead_dev_approvals(pr['requested_reviewers'], rm_team)
      puts "##-- is_no_pending_approvals:#{is_no_pending_approvals}"
      puts "##-- is_approved_rm:#{is_approved_rm}"
      puts "##-- is_approved_lead_dev:#{is_approved_lead_dev}"
      is_pr_approved = is_no_pending_approvals && is_approved_rm && is_approved_lead_dev
      if is_pr_approved
        puts "CHECK 3/3: PASS - PR was successfully approved by lead dev and release management team."
      else
        msg = "FAIL: Missing approval from Lead Dev and RM team!\nPlease approve it and open and close this PR to relaunch validation"
        check_errors << msg
        puts "CHECK 3/3: #{msg}"
      end

      if !jira_nbs.blank?
        update_jira_field_issues_from_JQL(jira_options,
                                          "id in (#{jira_nbs.join(',')})",
                                          'labels',
                                          [ (is_pr_approved)? JiraHelper::JIRA_LABEL_PR_APPROVED : JiraHelper::JIRA_LABEL_PR_CREATED],
                                          labels_to_delete)
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
  end

  ######################################################################################################
  # rake github:dispatch_labels[ghUsername,ghPassword,3346,'ci05build;ci06build;ci07build;ci08build']
  desc "Dispatch labels"
  task :dispatch_labels, [:ghUsername, :ghPassword, :pr_number, :labels] do |task, args|
    
    puts "STARTING", args
    @ghUsername = args[:ghUsername] || ''
    @ghPassword = args[:ghPassword] || ''
    pr_number  = args[:pr_number] || nil
    labels = args[:labels].split(";").uniq.compact  || ''
    
    selectedLabel=select_min_label(labels)
    puts "selectedLabel #{selectedLabel}"
    add_issue_label(selectedLabel, pr_number)
  end

  ######################################################################################################
  # rake github:filter_pr_labels[ghUsername,ghPassword,3346]
  desc "Filter the bundle labels from Github Pull request"
  task :filter_pr_labels, [:ghUsername, :ghPassword, :pr_number] do |task, args|

    #puts "STARTING", args

    # check the REQUIRED CLI ARGUMENTS
    puts "ERROR: 'ghUsername'and 'ghPassword' arguments are required !" if args[:ghUsername].blank? || args[:ghPassword].blank?
    puts "ERROR: 'pr_number' argument is required !" if args[:pr_number].blank?
    if args[:ghUsername].blank? || args[:ghPassword].blank? || args[:pr_number].blank?
      raise "Usage: rake github:filter_pr_labels[ghUsername,ghPassword,3346]"
    end

    # Check the REQUIRED Arguments and env Variables
    if ENV['BUNDLE_LABELS'].blank?
      puts "ERROR: 'BUNDLE_LABELS' environment variable is not set !"
      exit(1)
    end

    # used parameters
    @ghUsername = args[:ghUsername]
    @ghPassword = args[:ghPassword]
    pr_number  = args[:pr_number]

    # Used environment variables
    #puts "#### ENV['BUNDLE_LABELS']:#{ENV['BUNDLE_LABELS']}"
    bundle_labels = ENV['BUNDLE_LABELS'].split(";").uniq.compact || []

    puts "bundle_labels #### #{bundle_labels}"
    # get the PR
    pr = get_pr(pr_number)

    puts "pr #### #{pr}"

    # get the PR labels
    pr_labels = pr['labels'].map{|l| l['name']} || []

    puts "pr_labels #### #{pr_labels}"

    File.open("/tmp/#{pr_number}.txt",'w') do |filea|
     filea.puts "#{(bundle_labels & pr_labels).first}"
    end

    # print/return the first bundle label
    puts (bundle_labels & pr_labels).first
  end

end

namespace :notifications do
  # BUNDLE_GEMFILE="./scripts/Gemfile" rake notifications:daily_release['testresults_SFAuthUrl_CIBuildF.json','my@example.com;my2@example.com'] -f './scripts/Rakefile'
  desc "Notify by email the daily status of the release"
  task :daily_release, [:deploy_result_path, :static_code_analysis_results_path, :emails] do |task, args|
    puts "STARTING", args
    
    # psa smtp credentials
    smtp_username=ENV['SMTP_USERNAME']
    smtp_password=ENV['SMTP_PASSWORD']

    # check the smtp credential
    if smtp_username.blank? || smtp_password.blank?
      puts "SMTP credential SMTP_USERNAME SMTP_PASSWORD are not set !"
      puts "No email will be send"
      exit(1)
    end

    puts "ERROR: deploy_result_path is required !" if args[:deploy_result_path].blank?
    puts "ERROR: destination emails is required !" if args[:emails].blank?
    raise "Usage:  rake md_tools:convert_runtests_result_to_cobertura[testresults_SFAuthUrl_CIBuildF.json,pmd-results,email1@example.com;email2@example.com]" if args[:deploy_result_path].blank? || args[:emails].blank? 
    
    deploy_results_infos = extract_infos_from_deployment_results(args[:deploy_result_path])
    sca_results_infos = extract_infos_from_sca_results(args[:static_code_analysis_results_path])
    infos = deploy_results_infos.merge(sca_results_infos)
    NotifierMailer.daily_release(infos, args[:emails]).deliver_now # Creates the email and sends it immediately
    
  end

end
namespace :md_tools do

  # BUNDLE_GEMFILE="./scripts/Gemfile" rake md_tools:format_manifest['./manifest/package.xml','./manifest/package-out.xml'] -f './scripts/Rakefile'
  desc "Manifest formatter"
  task :format_manifest, [:manifest_path, :output] do |task, args|
    default_manifest_path = './manifest/*.xml'
    puts "No manifest path/file argument - Will be set to the default: #{default_manifest_path}" if args[:manifest_path].blank?
    manifest_path = args[:manifest_path] || default_manifest_path
    puts "STARTING", args
    format_package(manifest_path)
  end

  # BUNDLE_GEMFILE="./scripts/Gemfile" rake md_tools:merge_manifest['./manifest/package.xml','./manifest/package1.xml','./manifest/package2.xml] -f './scripts/Rakefile'
  desc "Manifest merger"
  task :merge_manifest, [:ancestor, :current, :other] do |task, args|
    #puts "STARTING", args
    merge_package(args[:ancestor], args[:current], args[:other])
  end

  # BUNDLE_GEMFILE="./scripts/Gemfile" rake md_tools:merge_manifest2['./manifest/package.xml','./manifest/package1.xml','./manifest/package2.xml] -f './scripts/Rakefile'
  desc "Manifest merger 2"
  task :merge_manifest2, [:manifest1, :manifest2, :output] do |task, args|
    #puts "STARTING", args
    merge_package2(args[:manifest1], args[:manifest2], args[:output])
  end

  # BUNDLE_GEMFILE="./scripts/Gemfile" rake md_tools:format_custom_labels['./force-app/main/default/labels/CustomLabels.labels-meta.xml','./force-app/main/default/labels/CustomLabels.labels-meta.xml'] -f './scripts/Rakefile'
  desc "CustomLabel formatter"
  task :format_custom_labels, [:input_path, :output_path] do |task, args|
    puts "STARTING", args
    format_custom_labels(args[:input_path], args[:output_path])
  end


  # rake md_tools:generate_package[48.0,mpsa_ci1dev,manifest/packagetest2f.xml,false] -f './scripts/Rakefile'
  desc "Generate package.xml file from a Salesforce org"
  task :generate_package, [:sfdx_org_alias,:api_version, :use_wildcard] do |task, args|
    puts "STARTING", args

    puts "ERROR: api version is required !" if args[:api_version].blank?
    puts "ERROR: sfdx org alias is required !" if args[:sfdx_org_alias].blank?
    #puts "ERROR: sfdx output_prefix alias is required !" if args[:output_prefix].blank?
    args[:use_wildcard]=true if args[:use_wildcard].blank?
    use_wildcard = !(args[:use_wildcard] == 'false')
    if args[:api_version].blank? || args[:sfdx_org_alias].blank? #|| args[:output_prefix].blank?
      raise "Usage:  rake md_tools:generate_package[dev38build,48.0]\n OR:  rake md_tools:generate_package[dev38build,48.0,false]"
    end

    #1 run sfdx force:describemetadata command
    mdt_list = describe_metadata(args[:api_version], args[:sfdx_org_alias])

    # Ignore some special metadata
    mdt_list.reject!{|mdt| IGNORED_METADATA_TYPES.include?(mdt) }

    # split the metadata type list into 2 parts:
    # 1- Component list that have dependencies with the profiles (should be retrieved in the same package)
    # 2- Component list that do not have any dependencies with other metadata components
    mdt_list_rel_profile, mdt_list_others = [],[]
    mdt_list.each { |mdt| MDT_RELATED_TO_PROFILES.include?(mdt) ?  mdt_list_rel_profile << mdt :  mdt_list_others << mdt }

    # List all metadata components with details
    all_md_components = []
    [mdt_list_rel_profile+mdt_list_others].flatten.each do |mdt|
      all_md_components.concat([list_metadata(mdt, args[:api_version], args[:sfdx_org_alias])])
    end

    # transform metadata to flat structure [{name: 'MetadataType', member: "ComponentName"}]
    all_md_components_flat = []
    all_md_components.each {|item| item.each{|k, v| v.each {|i| all_md_components_flat.concat([{name: k, member: i}])} }}

    # build a package with PACKAGE_LIMIT = 10 000 components by default (Salesforce limit in retrieve/deploy operations)
    all_md_components_flat.each_slice(PACKAGE_LIMIT).with_index do |mdt_slice,i|
      puts "Generating manifest/packages#{i}.xml ..."
      manifest = Manifest.new({})
      mdt_slice.each do |mdt|
        if use_wildcard && MDT_SUPPORT_WILDCARD.include?(mdt[:name])
          #puts "#{mdt[:name]} (*)"
          manifest.add({mdt[:name] => ["*"]})
        else
          manifest.add({mdt[:name] => mdt[:member]['fullName']})
        end
      end
      # save the slice in packages[0–n].xml
      package_file=File.join(File.expand_path('../../', __FILE__), "manifest/packages#{i}.xml")
      manifest.save_package_xml(package_file)
      puts "#{package_file} successfully generated !"
    end

  end

  # rake md_tools:update_metadata_describe[48.0,dev36build] -f './scripts/Rakefile'
  desc "Metadata Describe update"
  task :update_metadata_describe, [:api_version, :sfdx_org_alias] do |task, args|
    puts "STARTING", args
    puts "ERROR: api version is required !" if args[:api_version].blank?
    puts "ERROR: sfdx org alias is required !" if args[:sfdx_org_alias].blank?
    raise "Usage:  rake md_tools:update_metadata_describe[48.0,dev36build]" if args[:api_version].blank? || args[:sfdx_org_alias].blank? 
    #1 run sfdx force:describemetadata command
    md_describe_cmd= "sfdx force:mdapi:describemetadata -a #{args[:api_version]} -u #{args[:sfdx_org_alias]} --json"
    md_describe_result=`#{md_describe_cmd}`
    #2 parse de result
    md_describe_content = parse_json_content_to_hash(md_describe_result)
    if md_describe_content['status'] != '0'
      # get list of metadata type available in the sandbox/org
      md_objects =  md_describe_content['result']['metadataObjects']
      # transforme the hash keys to match the current code
      md_objects.each{ |item| item.deep_transform_keys! { |key| key.underscore } }
      # create a hash with xmlName as key
      md_objects_formatted = Hash[md_objects.map{|item| [item['xml_name'],item.reject{ |k| k == 'xml_name' } ]}]
      #md_objects_formatted.each{ |item| item.delete('xml_name') }
      md_desc_path=File.join(File.expand_path('../', __FILE__),'metadata-describe.json')
      save_file(md_desc_path, JSON.pretty_generate(md_objects_formatted))
      puts 'scripts/metadata-describe.json updated successully !'
    else
      raise "Error during the execution of the command: #{md_describe_cmd}"
    end
    
    
  end

  # rake md_tools:convert_deploy_result_to_junit[deploy_result.json,deploy_result.junit] -f './scripts/Rakefile'
  desc "Convert deployment result to Junit format"
  task :convert_deploy_result_to_junit, [:deploy_result_path, :output_path] do |task, args|
    puts "STARTING", args
    puts "ERROR: deploy_result_path is required !" if args[:deploy_result_path].blank?
    puts "ERROR: output_path is required !" if args[:output_path].blank?
    raise "Usage:  rake md_tools:convert_deploy_result_to_junit[deploy_result.json,deploy_result.junit]" if args[:deploy_result_path].blank? || args[:output_path].blank? 
    
    #1 parse deployment result file
    deploy_result_path =File.join(File.expand_path('../../', __FILE__),args[:deploy_result_path])
    
    deploy_result_content = File.open(deploy_result_path) do |f|
        JSON.parse(f.read).to_h 
    end

    result = deploy_result_content['result']
    runTestResult = result['details']['runTestResult']
    
    if result['details']['runTestResult']['successes'] || result['details']['runTestResult']['failures']
      junit_xml = build_junit_from_deployment_result(result)
      #puts junit_xml
      save_file(File.join(File.expand_path('../../', __FILE__),args[:output_path]), junit_xml)
      puts "Successully convert test results to junit  #{File.join(File.expand_path('../../', __FILE__),args[:output_path])}"
    else
      #puts "No test results found! \n #{deploy_result_content.to_json}"
      raise "No test results found! "
    end    
    
  end


  # rake md_tools:convert_deploy_result_to_cobertura[deploy_result.json,cobertura_coverage.xml] -f './scripts/Rakefile'
  desc "Convert deployment result to Cobertura coverage format"
  task :convert_deploy_result_to_cobertura, [:deploy_result_path, :output_path] do |task, args|
    puts "STARTING", args
    puts "ERROR: deploy_result_path is required !" if args[:deploy_result_path].blank?
    puts "ERROR: output_path is required !" if args[:output_path].blank?
    raise "Usage:  rake md_tools:convert_deploy_result_to_cobertura[deploy_result.json,coverage.xml]" if args[:deploy_result_path].blank? || args[:output_path].blank? 
    
    #1 parse deployment result file
    deploy_result_path =File.join(File.expand_path('../../', __FILE__),args[:deploy_result_path])
    
    deploy_result_content = File.open(deploy_result_path) do |f|
        JSON.parse(f.read).to_h 
    end

    result = deploy_result_content['result']
    runTestResult = result['details']['runTestResult']
    
    if runTestResult['codeCoverage'] 
      cobertura_xml = build_cobertura_from_deployment_result(result)
      #puts cobertura_xml
      save_file(File.join(File.expand_path('../../', __FILE__),args[:output_path]), cobertura_xml)
      puts "Successully convert deployment result to cobertura  #{File.join(File.expand_path('../../', __FILE__),args[:output_path])}"
    else
      #puts "No test results found! \n #{deploy_result_content.to_json}"
      raise "No test results found! "
    end    
    
  end

  # rake md_tools:convert_runtests_result_to_cobertura[testRunResultWithCoverage.json,runtest_coverage.xml] -f './scripts/Rakefile'
  desc "Convert runtests result to Cobertura coverage format"
  task :convert_runtests_result_to_cobertura, [:runtests_result_path, :output_path] do |task, args|
    puts "STARTING", args
    puts "ERROR: runtests_result_path is required !" if args[:runtests_result_path].blank?
    puts "ERROR: output_path is required !" if args[:output_path].blank?
    raise "Usage:  rake md_tools:convert_runtests_result_to_cobertura[testRunResultWithCoverage.json,coverage.xml]" if args[:runtests_result_path].blank? || args[:output_path].blank? 
    
    #1 parse deployment result file
    runtests_result_path =File.join(File.expand_path('../../', __FILE__),args[:runtests_result_path])
    
    runtests_result_content = File.open(runtests_result_path) do |f|
        JSON.parse(f.read).to_h 
    end

    result = runtests_result_content['result']
    
    if result['coverage']
      cobertura_xml = build_cobertura_from_runtests_result(result)
      #puts cobertura_xml
      raise "Error during parsing result ! \n #{result}"if cobertura_xml.blank?
      save_file(File.join(File.expand_path('../../', __FILE__),args[:output_path]), cobertura_xml)
      puts "Successully convert code coverage to cobertura  #{File.join(File.expand_path('../../', __FILE__),args[:output_path])}"
    else
      #puts "No code coverage found! \n #{runtests_result_content.to_json}"
      raise "No code coverage found! "
    end    
    
  end

  # BUNDLE_GEMFILE="./scripts/Gemfile" rake md_tools:extract_components[manifest/package.xml,ApexClass,*Test] -f './scripts/Rakefile'
  desc "Extract component from package"
  task :extract_components, [:manifest,:medata_type,:comp_filter] do |task, args|
    #puts "STARTING", args
    puts "ERROR: manifest file is required !" if args[:manifest].blank?
    puts "ERROR: metadata_type is required !" if args[:medata_type].blank?
    if args[:manifest].blank? || args[:medata_type].blank?
      raise "Usage:  rake md_tools:extract_components[manifest/package.xml,ExperienceBundle]\n or rake md_tools:extract_components[manifest/package.xml,ApexClass,*Test]"
    end
    medata_type = args[:medata_type]
    comp_filter = args[:comp_filter]
    manifest_path = File.expand_path(args[:manifest], PROJECT_ROOT)
    manifest = Manifest.new(manifest_path)
    extracted_components = manifest.get(medata_type,comp_filter)
    puts extracted_components.join(',')
  end
end
