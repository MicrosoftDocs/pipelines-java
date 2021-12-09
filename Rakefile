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
  
