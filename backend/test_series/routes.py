from fastapi import HTTPException, Header
from firebase_admin import firestore
import uuid

from .models import (
    TestGenerationRequest,
    TestSubmissionRequest,
)

from .performance import (
    get_student_level,
    get_recent_scores,
    calculate_new_level,
)

from .generation import generate_test

from .evaluation import (
    evaluate_mcq,
    evaluate_written_answer,
)
from .recommendation import (
    build_student_recommendation,
)

# REGISTER TEST SERIES ROUTES


def register_test_series_routes(
    app,
    db,
    client,
    verify_token,
):

    # GENERATE TEST

    @app.post("/generate-test")
    def generate_test_route(
        request: TestGenerationRequest,
        authorization: str = Header(None),
    ):

        # Verify Firebase user

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # Normalize input

        standard = (
            request.standard
            .lower()
            .replace("class", "")
            .replace("standard", "")
            .replace("th", "")
            .strip()
        )

        subject = request.subject.strip()
        chapter = request.chapter.strip()

        # Validate input

        if not standard:

            raise HTTPException(
                status_code=400,
                detail="Standard is required."
            )

        if not subject:

            raise HTTPException(
                status_code=400,
                detail="Subject is required."
            )

        if not chapter:

            raise HTTPException(
                status_code=400,
                detail="Chapter is required."
            )

        # Generate personalized test

        result = generate_test(
            db=db,
            client=client,
            uid=uid,
            standard=standard,
            subject=subject,
            chapter=chapter,
            source=request.source,
        )

        return {
            "status": "success",
            **result,
        }

    # SUBMIT TEST

    @app.post("/submit-test")
    def submit_test(
        request: TestSubmissionRequest,
        authorization: str = Header(None),
    ):

        # Verify Firebase user

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # Get generated test

        test_ref = (
            db.collection("generatedTests")
            .document(request.testId)
        )

        test_doc = test_ref.get()

        if not test_doc.exists:

            raise HTTPException(
                status_code=404,
                detail="Test not found."
            )

        test_data = test_doc.to_dict()

        # Verify ownership

        if test_data.get("userId") != uid:

            raise HTTPException(
                status_code=403,
                detail="You cannot submit this test."
            )

        # Prevent duplicate submission

        if test_data.get("status") == "completed":

            raise HTTPException(
                status_code=400,
                detail="This test has already been submitted."
            )

        questions = test_data.get(
            "questions",
            []
        )

        # Convert submitted answers to dictionary

        submitted_answers = {
            answer.questionId: answer.answer
            for answer in request.answers
        }

        # Counters

        correct_count = 0
        wrong_count = 0
        unanswered_count = 0

        total_marks = 0
        obtained_marks = 0

        topic_performance = {}
        question_results = []


        # EVALUATE QUESTIONS

        for question in questions:

            question_id = question.get(
                "questionId"
            )

            question_type = question.get(
                "type"
            )

            topic = question.get(
                "topic",
                "general"
            )

            user_answer = submitted_answers.get(
                question_id
            )

            
            # Initialize topic
            

            if topic not in topic_performance:

                topic_performance[topic] = {
                    "attempted": 0,
                    "correct": 0,
                    "wrong": 0,
                    "unanswered": 0,
                }

            # MCQ


            if question_type == "mcq":

                evaluation = evaluate_mcq(
                    question,
                    user_answer,
                )

                total_marks += 1

                topic_performance[
                    topic
                ]["attempted"] += (
                    0
                    if evaluation["isUnanswered"]
                    else 1
                )

                if evaluation["isUnanswered"]:

                    unanswered_count += 1

                    topic_performance[
                        topic
                    ]["unanswered"] += 1

                elif evaluation["isCorrect"]:

                    correct_count += 1
                    obtained_marks += 1

                    topic_performance[
                        topic
                    ]["correct"] += 1

                else:

                    wrong_count += 1

                    topic_performance[
                        topic
                    ]["wrong"] += 1

                question_results.append({

                    "questionId":
                        question_id,

                    "type":
                        "mcq",

                    "question":
                        question.get(
                            "question",
                            ""
                        ),

                    "options":
                        question.get(
                            "options",
                            []
                        ),

                    "correctAnswer":
                        question.get(
                            "correctAnswer"
                        ),

                    "userAnswer":
                        user_answer,

                    "isCorrect":
                        evaluation[
                            "isCorrect"
                        ],

                    "isUnanswered":
                        evaluation[
                            "isUnanswered"
                        ],

                    "topic":
                        topic,

                    "explanation":
                        question.get(
                            "explanation",
                            ""
                        ),
                })

    
            # WRITTEN
        

            elif question_type == "written":

                total_question_marks = int(
                    question.get(
                        "marks",
                        1
                    )
                )

                total_marks += (
                    total_question_marks
                )


                # Unanswered written question
                

                if (
                    user_answer is None
                    or not str(
                        user_answer
                    ).strip()
                ):

                    unanswered_count += 1

                    topic_performance[
                        topic
                    ]["unanswered"] += 1

                    question_results.append({

                        "questionId":
                            question_id,

                        "type":
                            "written",

                        "question":
                            question.get(
                                "question",
                                ""
                            ),

                        "userAnswer":
                            "",

                        "modelAnswer":
                            question.get(
                                "modelAnswer",
                                ""
                            ),

                        "marks":
                            total_question_marks,

                        "obtainedMarks":
                            0,

                        "topic":
                            topic,

                        "isCorrect":
                            False,

                        "isUnanswered":
                            True,
                    })

                    continue

                
                # Evaluate written answer
                

                evaluation = evaluate_written_answer(
                    client,
                    question,
                    user_answer,
                )

                obtained = evaluation[
                    "obtainedMarks"
                ]

                obtained_marks += obtained

                topic_performance[
                    topic
                ]["attempted"] += 1

                if evaluation["isCorrect"]:

                    topic_performance[
                        topic
                    ]["correct"] += 1

                else:

                    topic_performance[
                        topic
                    ]["wrong"] += 1

                question_results.append({

                    "questionId":
                        question_id,

                    "type":
                        "written",

                    "question":
                        question.get(
                            "question",
                            ""
                        ),

                    "userAnswer":
                        user_answer,

                    "modelAnswer":
                        question.get(
                            "modelAnswer",
                            ""
                        ),

                    "marks":
                        total_question_marks,

                    "obtainedMarks":
                        obtained,

                    "topic":
                        topic,

                    "isCorrect":
                        evaluation[
                            "isCorrect"
                        ],

                    "isUnanswered":
                        False,

                    "feedback":
                        evaluation[
                            "feedback"
                        ],
                })

        # SCORE

        if total_marks > 0:

            score = round(
                (
                    obtained_marks
                    / total_marks
                ) * 100,
                2
            )

        else:

            score = 0

        # TOPIC ACCURACY

        for topic, performance in (
            topic_performance.items()
        ):

            attempted = performance[
                "attempted"
            ]

            if attempted > 0:

                performance["accuracy"] = round(
                    (
                        performance["correct"]
                        / attempted
                    ) * 100,
                    2
                )

            else:

                performance["accuracy"] = 0

        # CREATE ATTEMPT ID

        attempt_id = str(
            uuid.uuid4()
        )

        # DETERMINE TEST NUMBER

        previous_attempts = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
            .where(
                "subject",
                "==",
                test_data.get("subject")
            )
            .where(
                "chapter",
                "==",
                test_data.get("chapter")
            )
            .stream()
        )

        test_number = 1

        for _ in previous_attempts:

            test_number += 1

        # SAVE ATTEMPT

        attempt_data = {

            "attemptId":
                attempt_id,

            "testId":
                request.testId,

            "subject":
                test_data.get(
                    "subject"
                ),

            "chapter":
                test_data.get(
                    "chapter"
                ),

            "standard":
                test_data.get(
                    "standard"
                ),

            "testNumber":
                test_number,

            "level":
                test_data.get(
                    "level"
                ),

            "totalQuestions":
                len(questions),

            "correctCount":
                correct_count,

            "wrongCount":
                wrong_count,

            "unansweredCount":
                unanswered_count,

            "totalMarks":
                total_marks,

            "obtainedMarks":
                obtained_marks,

            "score":
                score,

            "topicPerformance":
                topic_performance,

            "questions":
                question_results,

            "completedAt":
                firestore.SERVER_TIMESTAMP,
        }

        attempt_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
            .document(attempt_id)
        )

        attempt_ref.set(
            attempt_data
        )

        # UPDATE STUDENT LEVEL

        subject = test_data.get(
            "subject"
        )

        chapter = test_data.get(
            "chapter"
        )

        current_level = test_data.get(
            "level",
            "beginner"
        )

        recent_scores = get_recent_scores(
            db,
            uid,
            subject,
            chapter,
        )

        new_level = calculate_new_level(
            current_level,
            recent_scores,
        )

        print(
            "Previous Level:",
            current_level
        )

        print(
            "Recent Scores:",
            recent_scores
        )

        print(
            "New Level:",
            new_level
        )

        user_ref = (
            db.collection("users")
            .document(uid)
        )

        user_ref.set(
            {
                "subjectLevels": {
                    subject: new_level
                }
            },
            merge=True,
        )

        # MARK TEST AS COMPLETED

        test_ref.update({

            "status":
                "completed",

            "completedAt":
                firestore.SERVER_TIMESTAMP,

            "attemptId":
                attempt_id,
        })

        # RESPONSE

        return {

            "status":
                "success",

            "message":
                "Test submitted successfully.",

            "attemptId":
                attempt_id,

            "testNumber":
                test_number,

            "subject":
                subject,

            "chapter":
                chapter,

            "level":
                current_level,

            "totalQuestions":
                len(questions),

            "correctCount":
                correct_count,

            "wrongCount":
                wrong_count,

            "unansweredCount":
                unanswered_count,

            "totalMarks":
                total_marks,

            "obtainedMarks":
                obtained_marks,

            "score":
                score,

            "topicPerformance":
                topic_performance,

            "questions":
                question_results,
        }


    # TEST HISTORY

    @app.get("/test-history")
    def get_test_history(
        subject: str | None = None,
        chapter: str | None = None,
        authorization: str = Header(None),
    ):

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        attempts_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
        )

        query = attempts_ref

        if subject:

            query = query.where(
                "subject",
                "==",
                subject,
            )

        if chapter:

            query = query.where(
                "chapter",
                "==",
                chapter,
            )

        query = query.order_by(
            "completedAt",
            direction=firestore.Query.DESCENDING,
        ).limit(20)

        docs = query.stream()

        attempts = []

        for doc in docs:

            data = doc.to_dict() or {}

            attempts.append({

                "attemptId":
                    data.get(
                        "attemptId"
                    ),

                "testId":
                    data.get(
                        "testId"
                    ),

                "subject":
                    data.get(
                        "subject"
                    ),

                "chapter":
                    data.get(
                        "chapter"
                    ),

                "standard":
                    data.get(
                        "standard"
                    ),

                "testNumber":
                    data.get(
                        "testNumber"
                    ),

                "level":
                    data.get(
                        "level"
                    ),

                "totalQuestions":
                    data.get(
                        "totalQuestions"
                    ),

                "correctCount":
                    data.get(
                        "correctCount"
                    ),

                "wrongCount":
                    data.get(
                        "wrongCount"
                    ),

                "unansweredCount":
                    data.get(
                        "unansweredCount"
                    ),

                "totalMarks":
                    data.get(
                        "totalMarks"
                    ),

                "obtainedMarks":
                    data.get(
                        "obtainedMarks"
                    ),

                "score":
                    data.get(
                        "score"
                    ),

                "topicPerformance":
                    data.get(
                        "topicPerformance",
                        {}
                    ),

                "completedAt":
                    data.get(
                        "completedAt"
                    ),
            })

        return {

            "status":
                "success",

            "totalAttempts":
                len(attempts),

            "attempts":
                attempts,
        }

    # TEST RESULT

    @app.get("/test-result/{attempt_id}")
    def get_test_result(
        attempt_id: str,
        authorization: str = Header(None),
    ):

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        attempt_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
            .document(attempt_id)
        )

        attempt_doc = attempt_ref.get()

        if not attempt_doc.exists:

            raise HTTPException(
                status_code=404,
                detail="Test result not found."
            )

        attempt_data = (
            attempt_doc.to_dict()
            or {}
        )

        return {

            "status":
                "success",

            "attemptId":
                attempt_data.get(
                    "attemptId"
                ),

            "testId":
                attempt_data.get(
                    "testId"
                ),

            "subject":
                attempt_data.get(
                    "subject"
                ),

            "chapter":
                attempt_data.get(
                    "chapter"
                ),

            "standard":
                attempt_data.get(
                    "standard"
                ),

            "testNumber":
                attempt_data.get(
                    "testNumber"
                ),

            "level":
                attempt_data.get(
                    "level"
                ),

            "totalQuestions":
                attempt_data.get(
                    "totalQuestions"
                ),

            "correctCount":
                attempt_data.get(
                    "correctCount"
                ),

            "wrongCount":
                attempt_data.get(
                    "wrongCount"
                ),

            "unansweredCount":
                attempt_data.get(
                    "unansweredCount"
                ),

            "totalMarks":
                attempt_data.get(
                    "totalMarks"
                ),

            "obtainedMarks":
                attempt_data.get(
                    "obtainedMarks"
                ),

            "score":
                attempt_data.get(
                    "score"
                ),

            "topicPerformance":
                attempt_data.get(
                    "topicPerformance",
                    {}
                ),

            "questions":
                attempt_data.get(
                    "questions",
                    []
                ),

            "completedAt":
                attempt_data.get(
                    "completedAt"
                ),
        }

    # PROGRESS DASHBOARD
    
    @app.get("/progress-dashboard")
    def get_progress_dashboard(
        authorization: str = Header(None),
    ):
        # Verify Firebase user

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # Get user document

        user_ref = (
            db.collection("users")
            .document(uid)
        )

        user_doc = user_ref.get()

        if not user_doc.exists:
            raise HTTPException(
                status_code=404,
                detail="User profile not found."
            )

        user_data = user_doc.to_dict() or {}

        subject_levels = (
            user_data.get("subjectLevels", {})
        )

        # Get all test attempts

        attempts_ref = (
            user_ref
            .collection("testAttempts")
        )

        query = (
            attempts_ref
            .order_by(
                "completedAt",
                direction=firestore.Query.DESCENDING,
            )
            .limit(50)
        )

        docs = query.stream()

        attempts = []

        for doc in docs:

            data = doc.to_dict() or {}

            attempts.append({
                "attemptId":
                    data.get("attemptId"),

                "subject":
                    data.get("subject"),

                "chapter":
                    data.get("chapter"),

                "level":
                    data.get("level"),

                "testNumber":
                    data.get("testNumber"),

                "score":
                    data.get("score"),

                "correctCount":
                    data.get("correctCount"),

                "wrongCount":
                    data.get("wrongCount"),

                "unansweredCount":
                    data.get("unansweredCount"),

                "totalQuestions":
                    data.get("totalQuestions"),

                "topicPerformance":
                    data.get(
                        "topicPerformance",
                        {}
                    ),

                "completedAt":
                    data.get("completedAt"),
            })

        # Empty state

        if not attempts:

            return {
                "status": "success",

                "overall": {
                    "testsCompleted": 0,
                    "averageScore": None,
                    "highestScore": None,
                    "latestScore": None,
                },

                "subjects": subject_levels,

                "trend": [],

                "weakTopics": [],

                "recentTests": [],
                "latestTest": None,
            }

        # Overall statistics
        scores = [
            float(attempt["score"])
            for attempt in attempts
            if attempt.get("score") is not None
        ]

        latest_score = (
            scores[0]
            if scores
            else None
        )

        average_score = (
            round(
                sum(scores) / len(scores),
                2,
            )
            if scores
            else None
        )

        highest_score = (
            max(scores)
            if scores
            else None
        )

        # Subject statistics

        subject_stats = {}

        for attempt in attempts:

            subject = attempt.get("subject")

            if not subject:
                continue

            if subject not in subject_stats:

                subject_stats[subject] = {
                    "testsCompleted": 0,
                    "scores": [],
                }

            subject_stats[subject][
                "testsCompleted"
            ] += 1

            score = attempt.get("score")

            if score is not None:
                subject_stats[subject][
                    "scores"
                ].append(
                    float(score)
                )

        subjects = {}

        for subject, data in subject_stats.items():

            scores_list = data["scores"]

            subjects[subject] = {
                "testsCompleted":
                    data["testsCompleted"],

                "averageScore":
                    round(
                        sum(scores_list)
                        / len(scores_list),
                        2,
                    )
                    if scores_list
                    else None,

                "currentLevel":
                    subject_levels.get(
                        subject,
                        "beginner",
                    ),
            }

        # Include subjects from initial assessment
        # even if the student has not attempted
        # a Test Series test yet.

        for subject, level in subject_levels.items():

            if subject not in subjects:

                subjects[subject] = {
                    "testsCompleted": 0,
                    "averageScore": None,
                    "currentLevel": level,
                }

        # Performance trend

        trend = []

        for attempt in reversed(attempts[:10]):

            if attempt.get("score") is None:
                continue

            trend.append({
                "subject":
                    attempt.get("subject"),

                "chapter":
                    attempt.get("chapter"),

                "score":
                    attempt.get("score"),

                "completedAt":
                    attempt.get("completedAt"),
            })

        # Weak topics

        topic_data = {}

        for attempt in attempts:

            topic_performance = (
                attempt.get(
                    "topicPerformance",
                    {}
                )
            )

            for topic, performance in (
                topic_performance.items()
            ):

                accuracy = performance.get(
                    "accuracy"
                )

                if accuracy is None:
                    continue

                if topic not in topic_data:

                    topic_data[topic] = {
                        "accuracySum": 0,
                        "count": 0,
                        "subject":
                            attempt.get("subject"),
                        "chapter":
                            attempt.get("chapter"),
                    }

                topic_data[topic][
                    "accuracySum"
                ] += float(accuracy)

                topic_data[topic][
                    "count"
                ] += 1

        weak_topics = []

        for topic, data in topic_data.items():

            average_accuracy = round(
                data["accuracySum"]
                / data["count"],
                2,
            )

            if average_accuracy < 60:

                weak_topics.append({
                    "topic": topic,

                    "subject":
                        data["subject"],

                    "chapter":
                        data["chapter"],

                    "accuracy":
                        average_accuracy,
                })

        # Weakest topics first

        weak_topics.sort(
            key=lambda x: x["accuracy"]
        )

        weak_topics = weak_topics[:5]

        # Recent tests

        recent_tests = attempts[:5]
        # Latest test
        latest_test = attempts[0]
        # Response

        return {
            "status": "success",

            "overall": {
                "testsCompleted":
                    len(attempts),

                "averageScore":
                    average_score,

                "highestScore":
                    highest_score,

                "latestScore":
                    latest_score,
            },

            "subjects":
                subjects,

            "trend":
                trend,

            "weakTopics":
                weak_topics,

            "recentTests":
                recent_tests,
                "latestTest": {
                    "subject":
                        latest_test.get("subject"),

                    "chapter":
                        latest_test.get("chapter"),

                    "score":
                        latest_test.get("score"),

                    "level":
                        latest_test.get("level"),
                },
        }

    # TEST PROGRESS

    @app.get("/test-progress")
    def get_test_progress(
        subject: str,
        chapter: str,
        authorization: str = Header(None),
    ):

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        attempts_ref = (
            db.collection("users")
            .document(uid)
            .collection("testAttempts")
        )

        query = (
            attempts_ref
            .where(
                "subject",
                "==",
                subject,
            )
            .where(
                "chapter",
                "==",
                chapter,
            )
            .order_by(
                "completedAt",
                direction=firestore.Query.DESCENDING,
            )
        )

        docs = query.stream()

        attempts = []

        for doc in docs:

            data = doc.to_dict() or {}

            attempts.append(data)
        # No tests        

        if not attempts:

            current_level = get_student_level(
                db,
                uid,
                subject,
            )

            return {

                "status":
                    "success",

                "subject":
                    subject,

                "chapter":
                    chapter,

                "currentLevel":
                    current_level,

                "totalTests":
                    0,

                "latestScore":
                    None,

                "averageScore":
                    None,

                "highestScore":
                    None,

                "weakTopics":
                    {},
            }

        # Scores

        scores = []

        for attempt in attempts:

            score = attempt.get(
                "score"
            )

            if score is not None:

                scores.append(
                    float(score)
                )

        latest_score = (
            scores[0]
            if scores
            else None
        )

        average_score = (

            round(
                sum(scores)
                / len(scores),
                2,
            )

            if scores
            else None
        )

        highest_score = (

            max(scores)

            if scores
            else None
        )

        
        # Weak topics
        

        weak_topics = {}

        for attempt in attempts:

            topic_performance = (
                attempt.get(
                    "topicPerformance",
                    {}
                )
            )

            for topic, performance in (
                topic_performance.items()
            ):

                accuracy = performance.get(
                    "accuracy",
                    0,
                )

                if accuracy < 60:

                    if topic not in weak_topics:

                        weak_topics[topic] = {
                            "attempts": 0,
                            "accuracySum": 0,
                        }

                    weak_topics[topic][
                        "attempts"
                    ] += 1

                    weak_topics[topic][
                        "accuracySum"
                    ] += accuracy

        
        # Average topic accuracy
        

        for topic, data in (
            weak_topics.items()
        ):

            attempts_count = data[
                "attempts"
            ]

            data[
                "averageAccuracy"
            ] = round(
                data["accuracySum"]
                / attempts_count,
                2,
            )

            del data[
                "accuracySum"
            ]

        # Current level

        current_level = get_student_level(
            db,
            uid,
            subject,
        )

        return {

            "status":
                "success",

            "subject":
                subject,

            "chapter":
                chapter,

            "currentLevel":
                current_level,

            "totalTests":
                len(attempts),

            "latestScore":
                latest_score,

            "averageScore":
                average_score,

            "highestScore":
                highest_score,

            "weakTopics":
                weak_topics,
        }
    @app.get("/test-recommendation")
    def get_test_recommendation(
        subject: str,
        chapter: str,
        authorization: str = Header(None),
    ):
        # 
        # Verify Firebase user
        # 

        decoded_token = verify_token(
            authorization
        )

        uid = decoded_token["uid"]

        # 
        # Validate input
        # 

        subject = subject.strip()
        chapter = chapter.strip()

        if not subject:
            raise HTTPException(
                status_code=400,
                detail="Subject is required."
            )

        if not chapter:
            raise HTTPException(
                status_code=400,
                detail="Chapter is required."
            )
        
        # Get current student level

        current_level = get_student_level(
            db,
            uid,
            subject,
        )

        # Generate recommendation

        result = build_student_recommendation(
            db=db,
            uid=uid,
            subject=subject,
            chapter=chapter,
            current_level=current_level,
        )

        return {
            "status": "success",
            "subject": subject,
            "chapter": chapter,
            "currentLevel": current_level,
            "features": result["features"],
            "recommendation": result["recommendation"],
        }