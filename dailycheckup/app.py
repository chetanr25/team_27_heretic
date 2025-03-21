import streamlit as st
import json
import datetime
import os
from openai import OpenAI

# Page configuration
st.set_page_config(page_title="Patient Daily Checkup", layout="wide")

# Initialize session state variables if they don't exist
if 'patient_info' not in st.session_state:
    st.session_state.patient_info = {}
if 'treatment_type' not in st.session_state:
    st.session_state.treatment_type = ""
if 'questions' not in st.session_state:
    st.session_state.questions = []
if 'answers' not in st.session_state:
    st.session_state.answers = {}
if 'summary' not in st.session_state:
    st.session_state.summary = ""
if 'submitted' not in st.session_state:
    st.session_state.submitted = False
if 'summary_file_path' not in st.session_state:
    st.session_state.summary_file_path = ""

# Function to initialize the NVIDIA NIM-based OpenAI client


def get_nvidia_client():
    return OpenAI(
        base_url="https://integrate.api.nvidia.com/v1",
        api_key=st.session_state.nvidia_api_key
    )

# Function to generate questions using NVIDIA NIM API


def generate_questions(treatment_type):
    try:
        client = get_nvidia_client()

        prompt = f"""
        Generate 5-10 daily checkup questions for a patient undergoing {treatment_type} treatment.
        Questions should cover:
        - Physical symptoms
        - Pain levels
        - Medication adherence
        - Side effects
        - Mental wellbeing
        
        Format the response as a JSON list of questions. Only return the JSON.
        """

        completion = client.chat.completions.create(
            model="deepseek-ai/deepseek-r1",
            messages=[
                {"role": "system", "content": "You are a medical assistant generating daily checkup questions."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2,
            max_tokens=1000
        )

        response_text = completion.choices[0].message.content

        # Try to parse the JSON from the response
        try:
            # First attempt: try to parse the entire response as JSON
            questions_data = json.loads(response_text)

            # Handle different JSON formats the model might return
            if isinstance(questions_data, list):
                questions = questions_data
            elif isinstance(questions_data, dict) and "questions" in questions_data:
                questions = questions_data["questions"]
            else:
                # If it's a dict but doesn't have a "questions" key, get the first value that's a list
                for value in questions_data.values():
                    if isinstance(value, list):
                        questions = value
                        break
                else:
                    # Fallback if we couldn't find a list
                    questions = list(questions_data.values())

        except json.JSONDecodeError:
            # Second attempt: try to extract JSON part from the response
            import re
            json_match = re.search(
                r'(\[.*\]|\{.*\})', response_text, re.DOTALL)
            if json_match:
                try:
                    questions_data = json.loads(json_match.group(0))
                    if isinstance(questions_data, list):
                        questions = questions_data
                    elif isinstance(questions_data, dict) and "questions" in questions_data:
                        questions = questions_data["questions"]
                    else:
                        # Fallback to extracting questions from text
                        questions = [line.strip() for line in response_text.split('\n')
                                     if line.strip() and not line.strip().startswith('{') and not line.strip().startswith('}')]
                except:
                    # If JSON parsing fails, extract questions by line
                    questions = [line.strip() for line in response_text.split('\n')
                                 if line.strip() and not line.strip().startswith('{') and not line.strip().startswith('}')]
            else:
                # If no JSON-like structure found, split by lines or numbers
                questions = [line.strip() for line in response_text.split('\n')
                             if line.strip() and not line.strip().startswith('{') and not line.strip().startswith('}')]

        # Clean up questions (remove numbering, quotes, etc.)
        cleaned_questions = []
        for q in questions:
            # Remove numbering if present
            q = re.sub(r'^\d+[\.\)]\s*', '', q)
            # Remove quotes if present
            q = q.strip('"\'')
            # Add to cleaned list if not empty
            if q:
                cleaned_questions.append(q)

        return cleaned_questions[:10]  # Limit to max 10 questions

    except Exception as e:
        st.error(f"Error generating questions: {str(e)}")
        return ["How are you feeling today?",
                "Are you experiencing any pain (1-10 scale)?",
                "Have you taken all prescribed medications?",
                "Are you experiencing any side effects?",
                "How would you rate your mental wellbeing today (1-10)?"]

# Function to summarize responses using NVIDIA NIM API


def summarize_responses(patient_info, treatment_type, qa_pairs):
    try:
        client = get_nvidia_client()

        # Create input for the summary
        input_text = f"""
        Patient: {patient_info['name']} (ID: {patient_info['id']})
        Age: {patient_info['age']}
        Treatment: {treatment_type}
        Date: {datetime.datetime.now().strftime('%Y-%m-%d')}
        
        Daily Checkup Responses:
        """

        for question, answer in qa_pairs.items():
            input_text += f"\nQ: {question}\nA: {answer}\n"

        prompt = f"""
        Summarize the following patient daily checkup responses into concise observational notes for their doctor.
        Highlight any concerning symptoms, significant changes, or items that may require medical attention.
        
        {input_text}
        """

        completion = client.chat.completions.create(
            model="deepseek-ai/deepseek-r1",
            messages=[
                {"role": "system", "content": "You are a medical assistant summarizing patient checkup responses."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.3,
            max_tokens=1000
        )

        return completion.choices[0].message.content

    except Exception as e:
        st.error(f"Error summarizing responses: {str(e)}")
        return "Error generating summary. Please review the raw responses."

# Function to save summary to text file


def save_to_file(patient_info, treatment_type, summary):
    # Create reports directory if it doesn't exist
    os.makedirs("patient_reports", exist_ok=True)

    # Create filename with timestamp and patient ID
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"patient_reports/{patient_info['id']}_{timestamp}.txt"

    # Full report content
    report_content = f"""
PATIENT DAILY CHECKUP REPORT
============================
Date: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

PATIENT INFORMATION
------------------
Name: {patient_info['name']}
ID: {patient_info['id']}
Age: {patient_info['age']}
Treatment: {treatment_type}
Doctor: {patient_info['doctor']}

SUMMARY
-------
{summary}

RAW RESPONSES
------------
"""

    # Add raw responses
    for question, answer in st.session_state.answers.items():
        report_content += f"Q: {question}\nA: {answer}\n\n"

    # Write to file
    with open(filename, "w") as file:
        file.write(report_content)

    return filename


# Sidebar for configuration
with st.sidebar:
    st.title("🏥 Configuration")

    # API Key Input
    nvidia_api_key = st.text_input(
        "NVIDIA NIM API Key", value="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", type="password")
    if nvidia_api_key:
        st.session_state.nvidia_api_key = nvidia_api_key

    st.divider()

    # Only show patient info input if not already submitted today
    if not st.session_state.submitted:
        st.subheader("Patient Information")
        patient_name = st.text_input("Patient Name")
        patient_id = st.text_input("Patient ID")
        patient_age = st.number_input(
            "Patient Age", min_value=0, max_value=120, value=30)
        doctor_email = st.text_input("Doctor's Email")

        treatment_options = [
            "Chemotherapy",
            "Radiation Therapy",
            "Physical Therapy",
            "Psychiatric Treatment",
            "Post-Surgery Recovery",
            "Diabetes Management",
            "Cardiovascular Treatment",
            "Respiratory Therapy",
            "Pain Management",
            "Other"
        ]

        treatment_type = st.selectbox("Treatment Type", treatment_options)

        if treatment_type == "Other":
            treatment_type = st.text_input("Specify Treatment")

        if st.button("Set Patient Info"):
            if patient_name and patient_id and doctor_email and treatment_type:
                st.session_state.patient_info = {
                    "name": patient_name,
                    "id": patient_id,
                    "age": patient_age,
                    "doctor": doctor_email
                }
                st.session_state.treatment_type = treatment_type

                # Generate questions based on treatment type
                with st.spinner("Generating treatment-specific questions..."):
                    st.session_state.questions = generate_questions(
                        treatment_type)
                st.session_state.answers = {}
                st.success(
                    "Patient information set. Please proceed to the checkup.")
            else:
                st.error("Please fill in all required fields.")

# Main content area
st.title("📋 Patient Daily Checkup")

# Display patient info if available
if st.session_state.patient_info:
    st.write(
        f"#### Patient: {st.session_state.patient_info['name']} (ID: {st.session_state.patient_info['id']})")
    st.write(f"Treatment: {st.session_state.treatment_type}")
    st.write(f"Date: {datetime.datetime.now().strftime('%Y-%m-%d')}")

    # If checkup not submitted yet, show questions
    if not st.session_state.submitted:
        st.write("### Today's Checkup Questions")
        st.write(
            "Please answer the following questions about how you're feeling today:")

        with st.form("checkup_form"):
            # Display questions and collect answers
            for i, question in enumerate(st.session_state.questions):
                if question.endswith("(1-10 scale)?") or "rate" in question.lower() and "1-10" in question.lower():
                    st.session_state.answers[question] = st.slider(
                        question, 1, 10, 5)
                elif "taken all" in question.lower() or "medication" in question.lower():
                    st.session_state.answers[question] = st.radio(
                        question, ["Yes", "No", "Partially"])
                else:
                    st.session_state.answers[question] = st.text_area(
                        question, height=100)

            submitted = st.form_submit_button("Submit Checkup")

            if submitted:
                # Generate summary
                if 'nvidia_api_key' in st.session_state and st.session_state.nvidia_api_key:
                    with st.spinner("Generating summary of responses..."):
                        summary = summarize_responses(
                            st.session_state.patient_info,
                            st.session_state.treatment_type,
                            st.session_state.answers
                        )
                    st.session_state.summary = summary

                    # Save summary to file
                    file_path = save_to_file(
                        st.session_state.patient_info,
                        st.session_state.treatment_type,
                        summary
                    )
                    st.session_state.summary_file_path = file_path
                    st.session_state.submitted = True
                else:
                    st.error(
                        "Please enter your NVIDIA NIM API key in the sidebar.")
    else:
        # Show summary and file information
        st.write("### Daily Checkup Summary")
        st.write(st.session_state.summary)

        st.success(
            f"Summary saved to file: {st.session_state.summary_file_path}")

        # Add file download button
        if os.path.exists(st.session_state.summary_file_path):
            with open(st.session_state.summary_file_path, "r") as file:
                file_content = file.read()

            st.download_button(
                label="Download Report as Text File",
                data=file_content,
                file_name=os.path.basename(st.session_state.summary_file_path),
                mime="text/plain"
            )

        if st.button("Start New Checkup"):
            st.session_state.submitted = False
            st.session_state.answers = {}
            st.session_state.summary = ""
            st.session_state.summary_file_path = ""
            st.experimental_rerun()
else:
    st.info(
        "👈 Please enter patient information in the sidebar to begin the daily checkup.")

# Footer
st.divider()
st.write("© 2025 Patient Care Monitoring System")
