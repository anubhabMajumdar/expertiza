class Badge
	
	NUMBER_OF_BADGES = 5
	
	# CONSTANTS RELATED TO GOOD REVIEWER
	GOOD_REVIEW_THRESHOLD = 95
	GOOD_REVIEWER_BADGE_IMAGE = "<img id='good_reviewer_badge' src='/assets/badges/good_reviewer_badge.png' title = 'Good Reviewer'>"

	TOPPER_BADGE_IMAGE = "<img id='topper_badge' src='/assets/badges/topper_badge.png' title = 'Top Score'>"

	CONSISTENCY_THRESHOLD = 90
	CONSISTENCY_BADGE_IMAGE = "<img id='consistency_badge' src='/assets/badges/consistency_badge.png' title = 'Consistent'>"


	def self.get_badges(student_task_list)
		
		# create badge matrix
		current_assignment_count = 0
		badge_matrix = []
		consistency_flag = true

		student_task_list.each do |student_task|
			# insert a new row in badge matrix
			badge_matrix.push([false] * NUMBER_OF_BADGES)

			if not student_task.assignment.is_calibrated
			# check for different badges

			# Topper badge
			badge_matrix[current_assignment_count][0] = Badge.topper(student_task)

			# Good reviewer badge
			badge_matrix[current_assignment_count][2] = Badge.good_reviewer(student_task)

			# Consistency badge
			consistency_flag = consistency_flag && Badge.consistency(student_task)
			

			end

			current_assignment_count = current_assignment_count + 1
		end

		#--------------------------------- Decide on consistant badge ---------------------------------#

		if consistency_flag
			badge_matrix[-1][4] = CONSISTENCY_BADGE_IMAGE.html_safe
		end	


		# consistant_flag = true 
		# current_assignment_count = 0

		# student_task_list.each do |student_task|
		# 	if not badge_matrix[current_assignment_count][4]:
		# 		consistant_flag = false
		# 		break
		# 	end
		# 	current_assignment_count = current_assignment_count + 1
		# end

		# current_assignment_count = 0
		# student_task_list.each do |student_task|
		# 	badge_matrix[current_assignment_count][4] = false


		return badge_matrix
	
	end

	private

# -------------------------------------------- Good reviewer badge method(s)--------------------------------------------- #

	def self.good_reviewer(student_task)
		participant = student_task.participant
		if participant.try(:grade_for_reviewer).nil? or participant.try(:comment_for_reviewer).nil?
		      info = -1
		else
		      info = participant.try(:grade_for_reviewer)
		end

		if info >= GOOD_REVIEW_THRESHOLD
			return GOOD_REVIEWER_BADGE_IMAGE.html_safe
		else
			return false
		end
	end

# -------------------------------------------- Top Score badge method(s)--------------------------------------------- #

	def self.topper(student_task)
		assignment = student_task.assignment
		questions = {}
	    questionnaires = assignment.questionnaires

	    if assignment.varying_rubrics_by_round?
	      questions = Badge.retrieve_questions(questionnaires, assignment)
	    else # if this assignment does not have "varying rubric by rounds" feature
	      questionnaires.each do |questionnaire|
	        questions[questionnaire.symbol] = questionnaire.questions
	      end
	    end

	    scores = assignment.scores(questions)
	    
	    averages = Badge.calculate_average_vector(scores)
	    teams = Badge.get_teams(scores)
	    
	    max_average_index = averages.each_with_index.max[1]

	    if teams[max_average_index].participants.include?(student_task.participant)
			return TOPPER_BADGE_IMAGE.html_safe
	 	else
	 		return false
	 	end
	end

	def self.retrieve_questions(questionnaires, assignment)
		questions = {}
	    questionnaires.each do |questionnaire|
	      round = AssignmentQuestionnaire.where(assignment_id: assignment.id, questionnaire_id: questionnaire.id).first.used_in_round
	      questionnaire_symbol = if (!round.nil?)
	        (questionnaire.symbol.to_s+round.to_s).to_sym
	      else
	        questionnaire.symbol
	                             end
	      questions[questionnaire_symbol] = questionnaire.questions
	    end
	    return questions
  end

  def self.calculate_average_vector(scores)
    scores[:teams].reject! {|_k, v| v[:scores][:avg].nil? }
    scores[:teams].map {|_k, v| v[:scores][:avg].to_i }
  end

  def self.get_teams(hash)
  	teams = []
  	hash[:teams].reject! {|_k, v| v[:scores][:avg].nil? }
  	keys = hash[:teams].collect {|key,value| key}
  	keys.each do |key|
  		teams.push((hash[:teams][key][:team])) 
  	end
  	return teams
  end

# -------------------------------------------- Dream Team badge method(s)--------------------------------------------- #


# -------------------------------------------- First Submission badge method(s)--------------------------------------------- #


# -------------------------------------------- Consistency badge method(s)--------------------------------------------- #
  def self.consistency(student_task)
  	assignment = student_task.assignment
	questions = {}
    questionnaires = assignment.questionnaires

    if assignment.varying_rubrics_by_round?
      questions = Badge.retrieve_questions(questionnaires, assignment)
    else # if this assignment does not have "varying rubric by rounds" feature
      questionnaires.each do |questionnaire|
        questions[questionnaire.symbol] = questionnaire.questions
      end
    end

    participant = student_task.participant
    scores = participant.scores(questions)
    if scores[:review][:scores][:avg].to_i >= CONSISTENCY_THRESHOLD
    	return true
    else
    	return false	
  	end
  end

  
end