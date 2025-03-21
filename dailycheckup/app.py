import streamlit as st
import json
import datetime
import os
from openai import OpenAI
import hashlib
import pickle
import pandas as pd

# Mongo atlas connection

from pymongo.mongo_client import MongoClient
from pymongo.server_api import ServerApi

# Initialize MongoDB connection


def get_db_connection():
    uri = "mongodb+srv://vaib:12345@cluster0.gzqe7.mongodb.net/?appName=Cluster0"
    client = MongoClient(uri, server_api=ServerApi('1'))
    db = client["checkupDB"]
    return db

# Mongo atlas connection ends


# Page configuration
st.set_page_config(page_title="Patient Daily Checkup System", layout="wide")

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
if 'logged_in' not in st.session_state:
    st.session_state.logged_in = False
if 'user_type' not in st.session_state:
    st.session_state.user_type = None
if 'username' not in st.session_state:
    st.session_state.username = None
if 'page' not in st.session_state:
    st.session_state.page = "login"
if 'all_reports' not in st.session_state:
    st.session_state.all_reports = []

# Ensure directories exist
os.makedirs("patient_reports", exist_ok=True)
os.makedirs("data", exist_ok=True)

# User database functions - UPDATED to use MongoDB instead of pickle files


def save_users_db(users_db):
    db = get_db_connection()
    # Convert to a format MongoDB can store
    users_list = []
    for username, user_data in users_db.items():
        user_data_copy = user_data.copy()
        user_data_copy['_id'] = username  # Use username as document ID
        users_list.append(user_data_copy)

    # Clear existing collection and insert new data
    db.users.delete_many({})
    if users_list:
        db.users.insert_many(users_list)


def load_users_db():
    try:
        db = get_db_connection()
        users_db = {}
        for user in db.users.find():
            username = user.pop('_id')  # Get username from _id field
            users_db[username] = user
        return users_db
    except Exception as e:
        print(f"Error loading users: {e}")
        return {}

# Hash password


def hash_password(password):
    return hashlib.sha256(password.encode()).hexdigest()

# Function to get all patient reports


def get_all_reports():
    try:
        db = get_db_connection()
        reports = []

        for doc in db.patients.find():
            reports.append({
                "patient_id": doc["patient_id"],
                "patient_name": doc["patient_name"],
                "doctor": doc["doctor"],
                "date": doc["date"].strftime("%Y-%m-%d %H:%M"),
                "file_path": str(doc["_id"]),  # MongoDB ID as reference
                "filename": doc["filename"],
                "content": doc["content"]  # Store full content for display
            })

        return reports
    except Exception as e:
        st.error(f"Error fetching reports: {e}")
        return []

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
    try:
        db = get_db_connection()
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"{patient_info['id']}_{timestamp}.txt"

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

        # Store in MongoDB
        report_doc = {
            "filename": filename,
            "patient_id": patient_info['id'],
            "patient_name": patient_info['name'],
            "doctor": patient_info['doctor'],
            "treatment": treatment_type,
            "date": datetime.datetime.now(),
            "content": report_content,
            "summary": summary,
            "responses": [{
                "question": q,
                "answer": a
            } for q, a in st.session_state.answers.items()]
        }

        db.patients.insert_one(report_doc)

        return filename
    except Exception as e:
        st.error(f"Error saving report: {e}")
        return None

# Login/Registration Page


def show_login_page():
    st.title("🏥 Patient Care Monitoring System")

    tab1, tab2 = st.tabs(["Login", "Register"])

    with tab1:
        st.header("Login")
        username = st.text_input("Username", key="login_username")
        password = st.text_input(
            "Password", type="password", key="login_password")
        user_type = st.selectbox(
            "Login as", ["Doctor", "Patient"], key="login_type")

        if st.button("Login"):
            users_db = load_users_db()

            if username in users_db:
                stored_password = users_db[username]['password']
                if hash_password(password) == stored_password and users_db[username]['type'] == user_type.lower():
                    st.session_state.logged_in = True
                    st.session_state.user_type = user_type.lower()
                    st.session_state.username = username

                    if user_type.lower() == "doctor":
                        st.session_state.page = "doctor_dashboard"
                    else:
                        st.session_state.page = "patient_checkup"

                    st.success(f"Logged in as {user_type}: {username}")
                    st.experimental_rerun()
                else:
                    st.error("Invalid username, password or user type")
            else:
                st.error("User not found")

    with tab2:
        st.header("Register")
        new_username = st.text_input("Username", key="register_username")
        new_password = st.text_input(
            "Password", type="password", key="register_password")
        confirm_password = st.text_input("Confirm Password", type="password")
        new_user_type = st.selectbox(
            "Register as", ["Doctor", "Patient"], key="register_type")

        if new_user_type == "Doctor":
            doctor_specialty = st.text_input("Medical Specialty")
            doctor_email = st.text_input("Professional Email")
        else:
            patient_age = st.number_input(
                "Age", min_value=1, max_value=120, value=30)

        if st.button("Register"):
            if new_password != confirm_password:
                st.error("Passwords do not match")
            elif not new_username or not new_password:
                st.error("Username and password are required")
            else:
                users_db = load_users_db()

                if new_username in users_db:
                    st.error("Username already exists")
                else:
                    # Create user record
                    user_data = {
                        'username': new_username,
                        'password': hash_password(new_password),
                        'type': new_user_type.lower(),
                    }

                    if new_user_type == "Doctor":
                        user_data['specialty'] = doctor_specialty
                        user_data['email'] = doctor_email
                    else:
                        user_data['age'] = patient_age

                    users_db[new_username] = user_data
                    save_users_db(users_db)

                    st.success(
                        f"Successfully registered as {new_user_type}. Please log in.")

# Doctor Dashboard Page


def show_doctor_dashboard():
    st.title(f"👨‍⚕️ Doctor Dashboard - {st.session_state.username}")

    # Sidebar for doctor actions
    with st.sidebar:
        st.title("Actions")
        if st.button("Refresh Reports"):
            st.session_state.all_reports = get_all_reports()

        if st.button("Logout"):
            st.session_state.logged_in = False
            st.session_state.user_type = None
            st.session_state.username = None
            st.session_state.page = "login"
            st.experimental_rerun()

    # Get all reports if not already loaded
    if not st.session_state.all_reports:
        st.session_state.all_reports = get_all_reports()

    # Display reports in a table with filtering options
    st.subheader("Patient Reports")

    if not st.session_state.all_reports:
        st.info("No patient reports found.")
    else:
        # Convert to dataframe for easier filtering
        df = pd.DataFrame(st.session_state.all_reports)

        # Filters
        col1, col2 = st.columns(2)
        with col1:
            patient_filter = st.text_input("Filter by Patient Name or ID")
        with col2:
            date_filter = st.date_input(
                "Filter by Date", datetime.date.today())

        # Apply filters
        filtered_df = df.copy()
        if patient_filter:
            filtered_df = filtered_df[
                (filtered_df['patient_name'].str.contains(patient_filter, case=False)) |
                (filtered_df['patient_id'].str.contains(
                    patient_filter, case=False))
            ]

        # Get date string for comparison
        date_str = date_filter.strftime("%Y-%m-%d")
        filtered_df = filtered_df[filtered_df['date'].str.contains(date_str)]

        # Display filtered reports
        if filtered_df.empty:
            st.info("No reports match your filters.")
        else:
            # Display as a table with clickable links
            for _, row in filtered_df.iterrows():
                with st.expander(f"Patient: {row['patient_name']} - {row['date']}"):
                    st.write(f"**Patient ID:** {row['patient_id']}")
                    st.write(f"**Date:** {row['date']}")
                    st.write(f"**Doctor:** {row['doctor']}")

                    # Display report content directly from dataframe
                    report_content = row['content']
                    st.text_area("Report", report_content, height=300)

                    # Download button
                    st.download_button(
                        label="Download Report",
                        data=report_content,
                        file_name=row['filename'],
                        mime="text/plain"
                    )

# Patient Checkup Page


def show_patient_checkup():
    st.title(f"📋 Patient Daily Checkup - {st.session_state.username}")

    # Sidebar for patient actions
    with st.sidebar:
        st.title("🏥 Configuration")

        # API Key Input
        nvidia_api_key = st.text_input(
            "NVIDIA NIM API Key", value="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", type="password")
        if nvidia_api_key:
            st.session_state.nvidia_api_key = nvidia_api_key

        st.divider()

        if st.button("Logout"):
            st.session_state.logged_in = False
            st.session_state.user_type = None
            st.session_state.username = None
            st.session_state.page = "login"
            st.experimental_rerun()

        # Only show patient info input if not already submitted today
        if not st.session_state.submitted:
            st.subheader("Patient Information")

            # Pre-fill name from logged in username
            users_db = load_users_db()
            patient_name = st.session_state.username
            patient_id = st.text_input("Patient ID")

            # Pre-fill age if available
            if st.session_state.username in users_db and 'age' in users_db[st.session_state.username]:
                patient_age = st.number_input("Patient Age", min_value=0, max_value=120,
                                              value=users_db[st.session_state.username]['age'])
            else:
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

    # Main content area for patient checkup
    # Display patient info if available
    if st.session_state.patient_info:
        st.write(
            f"#### Patient: {st.session_state.patient_info['name']} (ID: {st.session_state.patient_info['id']})")
        st.write(f"Treatment: {st.session_state.treatment_type}")
        st.write(f"Date: {datetime.datetime.now().strftime('%Y-%m-%d')}")

        # If checkup not submitted yet, show questions
        if not st.session_state.submitted:
            # Rest of the checkup form functionality
            # ...existing code...
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
            # ...existing code...
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
                    file_name=os.path.basename(
                        st.session_state.summary_file_path),
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
            "Please enter patient information in the sidebar to begin the daily checkup.")

# Main app logic - determine which page to show


def main():
    if st.session_state.logged_in:
        if st.session_state.user_type == "doctor":
            if st.session_state.page == "doctor_dashboard":
                show_doctor_dashboard()
        else:  # Patient
            if st.session_state.page == "patient_checkup":
                show_patient_checkup()
    else:
        show_login_page()


# Run the app
if __name__ == "__main__":
    main()
