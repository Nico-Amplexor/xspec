#!/usr/bin/env bats
#===============================================================================
#
#         USAGE:  bats xspec.bats 
#         
#   DESCRIPTION:  Unit tests for script bin/xspec.sh 
#
#         INPUT:  N/A
#
#        OUTPUT:  Unit tests results
#
#  DEPENDENCIES:  This script requires bats (https://github.com/sstephenson/bats)
#
#        AUTHOR:  Sandro Cirulli, github.com/cirulls
#
#       LICENSE:  MIT License (https://opensource.org/licenses/MIT)
#
#===============================================================================

setup() {
	work_dir="${BATS_TMPDIR}/xspec/bats_work"
	mkdir -p "${work_dir}"
	mkdir ../test/catalog/xspec
	mkdir ../test/xspec
	mkdir ../tutorial/schematron/xspec
	mkdir ../tutorial/xspec
}


teardown() {
	rm -rf "${work_dir}"
	rm -rf ../test/catalog/xspec
	rm -rf ../test/xspec
	rm -rf ../tutorial/schematron/xspec
	rm -rf ../tutorial/xspec
}


@test "invoking xspec without arguments prints usage" {
    run ../bin/xspec.sh
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[2]}" = "Usage: xspec [-t|-q|-s|-c|-j|-catalog file|-h] file [coverage]" ]
}


@test "invoking xspec without arguments prints usage even if Saxon environment variables are not defined" {
    unset SAXON_CP
    run ../bin/xspec.sh
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "SAXON_CP and SAXON_HOME both not set!" ]
    [[ "${lines[4]}" =~ "Usage: xspec " ]]
}


@test "invoking xspec with -h prints usage and does so even when it is 11th argument" {
    run ../bin/xspec.sh -t -t -t -t -t -t -t -t -t -t -h
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${lines[1]}" =~ "Usage: xspec " ]]
}


@test "invoking xspec with -s and -t prints error message" {
    run ../bin/xspec.sh -s -t
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "-s and -t are mutually exclusive" ]
}


@test "invoking xspec with -s and -q prints error message" {
    run ../bin/xspec.sh -s -q
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "-s and -q are mutually exclusive" ]
}


@test "invoking xspec with -t and -q prints error message" {
    run ../bin/xspec.sh -t -q
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "-t and -q are mutually exclusive" ]
}


@test "invoking xspec -c with Saxon9HE returns error message" {
    export SAXON_CP=/path/to/saxon9he.jar
    run ../bin/xspec.sh -c ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Code coverage requires Saxon extension functions which are available only under Saxon9EE or Saxon9PE." ]
}


@test "invoking xspec -c with Saxon9SA returns error message" {
    export SAXON_CP=/path/to/saxon9sa.jar
    run ../bin/xspec.sh -c ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Code coverage requires Saxon extension functions which are available only under Saxon9EE or Saxon9PE." ]
}


@test "invoking xspec -c with Saxon9 returns error message" {
    export SAXON_CP=/path/to/saxon9.jar
    run ../bin/xspec.sh -c ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Code coverage requires Saxon extension functions which are available only under Saxon9EE or Saxon9PE." ]
}


@test "invoking xspec -c with Saxon8SA returns error message" {
    export SAXON_CP=/path/to/saxon8sa.jar
    run ../bin/xspec.sh -c ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Code coverage requires Saxon extension functions which are available only under Saxon9EE or Saxon9PE." ]
}


@test "invoking xspec -c with Saxon8 returns error message" {
    export SAXON_CP=/path/to/saxon8.jar
    run ../bin/xspec.sh -c ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Code coverage requires Saxon extension functions which are available only under Saxon9EE or Saxon9PE." ]
}


@test "invoking xspec -c with Saxon9EE creates test stylesheet" {
    # Append non-Saxon jar to see if SAXON_CP is parsed correctly
    export SAXON_CP="/path/to/saxon9ee.jar:/path/to/another.jar"
    run ../bin/xspec.sh -c ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Creating Test Stylesheet..." ]
}


@test "invoking xspec -c with Saxon9PE creates test stylesheet" {
    export SAXON_CP=/path/to/saxon9pe.jar
    run ../bin/xspec.sh -c ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Creating Test Stylesheet..." ]
}


@test "invoking xspec -c creates report files" {
    if [ -z "${XSLT_SUPPORTS_COVERAGE}" ]; then
        skip "XSLT_SUPPORTS_COVERAGE is not defined"
    fi

    # TODO: Non alphanumeric path #208
    special_chars_dir="${work_dir}/up and down"
    mkdir "${special_chars_dir}"

    cp ../tutorial/coverage/demo* "${special_chars_dir}"
    run ../bin/xspec.sh -c "${special_chars_dir}/demo.xspec"
    echo "$output"
    [ "$status" -eq 0 ]

    # XML, HTML and coverage report file
    [ -f "${special_chars_dir}/xspec/demo-result.xml" ]
    [ -f "${special_chars_dir}/xspec/demo-result.html" ]
    [ -f "${special_chars_dir}/xspec/demo-coverage.html" ]
}


@test "invoking xspec -c -q prints error message" {
    export SAXON_CP=/path/to/saxon9ee.jar
    run ../bin/xspec.sh -c -q ../tutorial/xquery-tutorial.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Coverage is supported only for XSLT" ]
}


@test "invoking xspec -c -s prints error message" {
    export SAXON_CP=/path/to/saxon9ee.jar
    run ../bin/xspec.sh -c -s ../tutorial/schematron/demo-01.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Coverage is supported only for XSLT" ]
}


@test "invoking xspec generates message with default report location and creates report files" {
    run ../bin/xspec.sh ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[18]}" = "Report available at ../tutorial/xspec/escape-for-regex-result.html" ]

    # XML report file is created
    [ -f "../tutorial/xspec/escape-for-regex-result.xml" ]

    # HTML report file is created and contains CSS inline #135
    run java -jar "${SAXON_JAR}" -s:../tutorial/xspec/escape-for-regex-result.html -xsl:html-css.xsl
    echo "$output"
    [ "${lines[0]}" = "true" ]

    # Coverage is disabled by default
    [ ! -f "../tutorial/xspec/escape-for-regex-coverage.xml" ]

    # JUnit is disabled by default
    [ ! -f "../tutorial/xspec/escape-for-regex-junit.xml" ]
}


@test "invoking xspec with -j option with Saxon8 returns error message" {
    export SAXON_CP=/path/to/saxon8.jar
    run ../bin/xspec.sh -j ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Saxon8 detected. JUnit report requires Saxon9." ]
}


@test "invoking xspec with -j option with Saxon8-SA returns error message" {
    export SAXON_CP=/path/to/saxon8sa.jar
    run ../bin/xspec.sh -j ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Saxon8 detected. JUnit report requires Saxon9." ]
}


@test "invoking xspec with -j option generates message with JUnit report location and creates report files" {
    run ../bin/xspec.sh -j ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[18]}" = "Report available at ../tutorial/xspec/escape-for-regex-junit.xml" ]

    # XML report file
    [ -f "../tutorial/xspec/escape-for-regex-result.xml" ]

    # HTML report file
    [ -f "../tutorial/xspec/escape-for-regex-result.html" ]

    # JUnit report file
    [ -f "../tutorial/xspec/escape-for-regex-junit.xml" ]
}


@test "invoking xspec with Saxon-B-9-1-0-8 creates test stylesheet" {
    export SAXON_CP=/path/to/saxonb9-1-0-8.jar
    run ../bin/xspec.sh ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [ "${lines[1]}" = "Creating Test Stylesheet..." ]
}


@test "invoking xspec with TEST_DIR already set externally generates files inside TEST_DIR" {
    export TEST_DIR="${work_dir}"
    run ../bin/xspec.sh ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[18]}" = "Report available at ${TEST_DIR}/escape-for-regex-result.html" ]
}


@test "invoking xspec that passes a non xs:boolean does not raise a warning #46" {
    run ../bin/xspec.sh xspec-46.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${lines[3]}" =~ "Testing with" ]]
}


@test "executing the Saxon XProc harness generates a report with UTF-8 encoding" {
    if [ -z "${XMLCALABASH_JAR}" ]; then
        skip "XMLCALABASH_JAR is not defined"
    fi

    run java -Xmx1024m -cp "${XMLCALABASH_JAR}" com.xmlcalabash.drivers.Main -isource=xspec-72.xspec -p xspec-home=file:${PWD}/../ -oresult=xspec/xspec-72-result.html ../src/harnesses/saxon/saxon-xslt-harness.xproc
    run java -jar "${SAXON_JAR}" -s:xspec/xspec-72-result.html -xsl:html-charset.xsl
    echo "$output"
    [ "${lines[0]}" = "true" ]
}


@test "invoking xspec with path containing parentheses #84, an apostrophe #119 or an ampersand #202 runs successfully and generates HTML report file" {
    special_chars_dir="${work_dir}/some'path (84) here & there"
    mkdir "${special_chars_dir}"
    cp ../tutorial/escape-for-regex.* "${special_chars_dir}"

    expected_report="${special_chars_dir}/xspec/escape-for-regex-result.html"

    run ../bin/xspec.sh "${special_chars_dir}/escape-for-regex.xspec"
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[19]}" = "Report available at ${expected_report}" ]
    [ -f "${expected_report}" ]
}


@test "invoking xspec with saxon script uses the saxon script #121 #122" {
    echo "echo 'Saxon script with EXPath Packaging System'" > "${work_dir}/saxon"
    chmod +x "${work_dir}/saxon"
    export PATH="$PATH:${work_dir}"
    run ../bin/xspec.sh ../tutorial/escape-for-regex.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[0]}" = "Saxon script found, use it." ]
}


@test "Schematron phase/parameters are passed to Schematron compile" {
    run ../bin/xspec.sh -s schematron-param-001.xspec
    echo "${lines[2]}"
    [ "$status" -eq 0 ]
    [ "${lines[2]}" == "Parameters: phase=P1 ?selected=codepoints-to-string((80,49))" ]
}

@test "invoking xspec with Schematron XSLTs provided externally uses provided XSLTs for Schematron compile" {
    export SCHEMATRON_XSLT_INCLUDE=schematron/schematron-xslt-include.xsl
    export SCHEMATRON_XSLT_EXPAND=schematron/schematron-xslt-expand.xsl
    export SCHEMATRON_XSLT_COMPILE=schematron/schematron-xslt-compile.xsl

    run ../bin/xspec.sh -s ../tutorial/schematron/demo-01.xspec
    echo "$output"
    [ "${lines[4]}" = "Schematron XSLT include" ]
    [ "${lines[5]}" = "Schematron XSLT expand" ]
    [ "${lines[6]}" = "Schematron XSLT compile" ]

    # With the provided dummy XSLTs, XSpec leaves temp files. Delete them.
    rm ../tutorial/schematron/demo-01.sch-compiled.xsl
    rm ../tutorial/schematron/demo-01.xspec-compiled.xspec
}


@test "invoking xspec with the -s option does not display Schematron warnings #129 #131 and removes temporary files" {
    run ../bin/xspec.sh -s ../tutorial/schematron/demo-03.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[4]}" == "Compiling the Schematron tests..." ]

    # Cleanup removes compiled .xspec
    [ ! -f "../tutorial/schematron/demo-03.xspec-compiled.xspec" ]

    # Cleanup removes temporary files in TEST_DIR
    run ls ../tutorial/schematron/xspec
    echo "$output"
    [ "${#lines[@]}" = "3" ]
    [ "${lines[0]}" = "demo-03-result.html" ]
    [ "${lines[1]}" = "demo-03-result.xml" ]
    [ "${lines[2]}" = "demo-03.xsl" ]
}


@test "invoking xspec with -q option runs XSpec test for XQuery" {
    run ../bin/xspec.sh -q ../tutorial/xquery-tutorial.xspec
    echo "${lines[5]}"
    [ "$status" -eq 0 ]
    [ "${lines[5]}" = "passed: 1 / pending: 0 / failed: 0 / total: 1" ]
}


@test "executing the XProc harness for BaseX generates a report" {
    if [ -z "${BASEX_JAR}" ]; then
        skip "BASEX_JAR is not defined"
    fi
    if [ -z "${XMLCALABASH_JAR}" ]; then
        skip "XMLCALABASH_JAR is not defined"
    fi

    compiled_file="${work_dir}/compiled.xq"
    run java -Xmx1024m -cp "${XMLCALABASH_JAR}" com.xmlcalabash.drivers.Main -i source=../tutorial/xquery-tutorial.xspec -p xspec-home=file:${PWD}/../ -p basex-jar="${BASEX_JAR}" -p compiled-file="file:${compiled_file}" -o result=xspec/xquery-tutorial-result.html ../src/harnesses/basex/basex-standalone-xquery-harness.xproc
    echo "$output"
    [[ "${output}" =~ "src/harnesses/harness-lib.xpl:267:45:passed: 1 / pending: 0 / failed: 0 / total: 1" ]]

    # compiled-file
    [ -f "${compiled_file}" ]
}


@test "Ant for XSLT with default properties fails on test failure" {
    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/../tutorial/escape-for-regex.xspec -lib "${SAXON_JAR}"
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "passed: 5 / pending: 0 / failed: 1 / total: 6" ]]
    [[ "${output}" =~ "BUILD FAILED" ]]

    # Default xspec.coverage.enabled is false
    [ ! -f "../tutorial/xspec/escape-for-regex-coverage.xml" ]

    # Default xspec.junit.enabled is false
    [ ! -f "../tutorial/xspec/escape-for-regex-junit.xml" ]
}


@test "Ant for XSLT with xspec.fail=false continues on test failure" {
    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/../tutorial/escape-for-regex.xspec -lib "${SAXON_JAR}" -Dxspec.fail=false
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 5 / pending: 0 / failed: 1 / total: 6" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]
}


@test "Ant for XSLT with catalog resolves URI" {
    if [ -z "${XML_RESOLVER_JAR}" ]; then
        skip "XML_RESOLVER_JAR is not defined"
    fi

    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/catalog/xspec-160_xslt.xspec -lib "${SAXON_JAR}" -Dxspec.fail=false -Dcatalog=${PWD}/catalog/xspec-160_catalog.xml -lib "${XML_RESOLVER_JAR}"
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 5 / pending: 0 / failed: 1 / total: 6" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]
}


@test "Ant for XQuery with default properties" {
    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/../tutorial/xquery-tutorial.xspec -lib "${SAXON_JAR}" -Dtest.type=q
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 1 / pending: 0 / failed: 0 / total: 1" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]
}


@test "Ant for Schematron with minimum properties #168" {
    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/../tutorial/schematron/demo-03.xspec -lib "${SAXON_JAR}" -Dtest.type=s
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 10 / pending: 1 / failed: 0 / total: 11" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]

    # Verify that the default clean.output.dir is false and leaves temp files. Delete the left files at the same time.
    [  -d "../tutorial/schematron/xspec/" ]
    rm    "../tutorial/schematron/demo-03.xspec-compiled.xspec"
    rm    "../tutorial/schematron/demo-03.sch-compiled.xsl"
}


@test "Ant for Schematron with various properties except catalog" {
    build_xml="${work_dir}/build.xml"
    ant_test_dir="${work_dir}/ant-temp"

    # Remove a temp dir created by setup
    rm -r ../tutorial/schematron/xspec

    # For testing -Dxspec.project.dir
    cp ../build.xml "${build_xml}"

    run ant -buildfile "${build_xml}" -Dxspec.xml=${PWD}/../tutorial/schematron/demo-03.xspec -lib "${SAXON_JAR}" -Dxspec.properties=${PWD}/schematron.properties -Dxspec.project.dir=${PWD}/.. -Dxspec.phase=#ALL -Dxspec.dir="${ant_test_dir}" -Dclean.output.dir=true
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 10 / pending: 1 / failed: 0 / total: 11" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]

    # Verify that -Dxspec-dir was honered and the default dir was not created
    [ ! -d "../tutorial/schematron/xspec/" ]

    # Verify clean.output.dir=true
    [ ! -d "${ant_test_dir}" ]
    [ ! -f "../tutorial/schematron/demo-03.xspec-compiled.xspec" ]
    [ ! -f "../tutorial/schematron/demo-03.sch-compiled.xsl" ]
}


@test "Ant for Schematron with catalog and default xspec.fail fails on test failure" {
    if [ -z "${XML_RESOLVER_JAR}" ]; then
        skip "XML_RESOLVER_JAR is not defined"
    fi

    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/catalog/xspec-160_schematron.xspec -lib "${SAXON_JAR}" -Dtest.type=s -Dxspec.phase=#ALL -Dclean.output.dir=true -Dcatalog=${PWD}/catalog/xspec-160_catalog.xml -lib "${XML_RESOLVER_JAR}"
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "passed: 6 / pending: 0 / failed: 1 / total: 7" ]]
    [[ "${output}" =~ "BUILD FAILED" ]]

    # Verify the build fails before cleanup
    [  -d "catalog/xspec/" ]

    # Verify that the build fails after Schematron setup and leaves temp files. Delete them at the same time.
    rm "catalog/xspec-160_schematron.xspec-compiled.xspec"
    rm "../tutorial/schematron/demo-04.sch-compiled.xsl"
}


@test "Ant for Schematron with catalog and xspec.fail=false continues on test failure" {
    if [ -z "${XML_RESOLVER_JAR}" ]; then
        skip "XML_RESOLVER_JAR is not defined"
    fi

    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/catalog/xspec-160_schematron.xspec -lib "${SAXON_JAR}" -Dtest.type=s -Dxspec.phase=#ALL -Dclean.output.dir=true -Dcatalog=${PWD}/catalog/xspec-160_catalog.xml -lib "${XML_RESOLVER_JAR}" -Dxspec.fail=false
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 6 / pending: 0 / failed: 1 / total: 7" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]
}

@test "invoking xspec for XSLT with -catalog uses XML Catalog resolver and does so even with spaces in file path" {
    if [ -z "${XML_RESOLVER_JAR}" ]; then
        skip "XML_RESOLVER_JAR is not defined"
    fi

    space_dir="${work_dir}/cat a log"
    mkdir -p "${space_dir}/xspec"
    cp catalog/catalog-01* "${space_dir}"

    export SAXON_CP="$SAXON_JAR:$XML_RESOLVER_JAR"
    run ../bin/xspec.sh -catalog "${space_dir}/catalog-01-catalog.xml" "${space_dir}/catalog-01-xslt.xspec"
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[7]}" = "passed: 1 / pending: 0 / failed: 0 / total: 1" ]
}

@test "invoking xspec for XQuery with -catalog uses XML Catalog resolver" {
    if [ -z "${XML_RESOLVER_JAR}" ]; then
        skip "XML_RESOLVER_JAR is not defined"
    fi

    export SAXON_CP="$SAXON_JAR:$XML_RESOLVER_JAR"
    run ../bin/xspec.sh -catalog catalog/catalog-01-catalog.xml -q catalog/catalog-01-xquery.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[5]}" = "passed: 1 / pending: 0 / failed: 0 / total: 1" ]
}

@test "invoking xspec with XML_CATALOG set uses XML Catalog resolver and does so even with spaces in file path" {
    if [ -z "${XML_RESOLVER_JAR}" ]; then
        skip "XML_RESOLVER_JAR is not defined"
    fi

    space_dir="${work_dir}/cat a log"
    mkdir -p "${space_dir}/xspec"
    cp catalog/catalog-01* "${space_dir}"

    export SAXON_CP="$SAXON_JAR:$XML_RESOLVER_JAR"
    export XML_CATALOG="${space_dir}/catalog-01-catalog.xml"
    run ../bin/xspec.sh "${space_dir}/catalog-01-xslt.xspec"
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[7]}" = "passed: 1 / pending: 0 / failed: 0 / total: 1" ]
}

@test "invoking xspec using SAXON_HOME finds Saxon jar and XML Catalog Resolver jar" {
    if [ -z "${XML_RESOLVER_JAR}" ]; then
        skip "XML_RESOLVER_JAR is not defined"
    fi

    export SAXON_HOME="${work_dir}/saxon"
    mkdir "${SAXON_HOME}"
    cp "${SAXON_JAR}" "${SAXON_HOME}"
    cp "${XML_RESOLVER_JAR}" "${SAXON_HOME}/xml-resolver-1.2.jar"
    unset SAXON_CP

    # To avoid "No license file found" warning on commercial Saxon
    saxon_license="$(dirname -- "${SAXON_JAR}")/saxon-license.lic"
    if [ -f "${saxon_license}" ]; then
        cp "${saxon_license}" "${SAXON_HOME}"
    fi

    run ../bin/xspec.sh -catalog catalog/catalog-01-catalog.xml catalog/catalog-01-xslt.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[7]}" = "passed: 1 / pending: 0 / failed: 0 / total: 1" ]
}


@test "Schema detects no error in tutorial" {
    if [ -z "${JING_JAR}" ]; then
        skip "JING_JAR is not defined"
    fi

    run java -jar "${JING_JAR}" -c ../src/schemas/xspec.rnc \
        ../tutorial/*.xspec \
        ../tutorial/coverage/*.xspec \
        ../tutorial/schematron/*.xspec
    echo "$output"
    [ "$status" -eq 0 ]
}


@test "Schema detects no error in known good tests" {
    if [ -z "${JING_JAR}" ]; then
        skip "JING_JAR is not defined"
    fi

    run java -jar "${JING_JAR}" -c ../src/schemas/xspec.rnc \
        catalog/*.xspec \
        end-to-end/cases/*.xspec \
        schematron/*-import.xspec \
        schematron/*-in.xspec
    echo "$output"
    [ "$status" -eq 0 ]
}


@test "Schema detects errors in node-selection test" {
    if [ -z "${JING_JAR}" ]; then
        skip "JING_JAR is not defined"
    fi

    # -t for identifying the last line
    run java -jar "${JING_JAR}" -c -t ../src/schemas/xspec.rnc xspec-node-selection.xspec
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "${lines[0]}" =~ "-child-not-allowed" ]]
    [[ "${lines[1]}" =~ "-child-not-allowed" ]]
    [[ "${lines[2]}" =~ "-child-not-allowed" ]]
    [[ "${lines[3]}" =~ "-child-not-allowed" ]]
    [[ "${lines[4]}" =~ "-child-not-allowed" ]]
    [[ "${lines[5]}" =~ "Elapsed time" ]]
}


@test "Ant for XSLT with saxon.custom.options" {
    # Test with a space in file name
    saxon_config="${work_dir}/saxon config.xml"
    cp saxon-custom-options/config.xml "${saxon_config}"

    # via properties file, to convey the options in a stable manner...
    xspec_properties="${work_dir}/xspec.properties"
    echo "saxon.custom.options=-config:\"${saxon_config}\" -t" > "${xspec_properties}"

    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/saxon-custom-options/test.xspec -lib "${SAXON_JAR}" -Dxspec.properties="${xspec_properties}"
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 1 / pending: 0 / failed: 0 / total: 1" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]

    # Verify '-t'
    [[ "${output}" =~ "Memory used:" ]]
}


@test "Ant for XQuery with saxon.custom.options" {
    # Test with a space in file name
    saxon_config="${work_dir}/saxon config.xml"
    cp saxon-custom-options/config.xml "${saxon_config}"

    # via properties file, to convey the options in a stable manner...
    xspec_properties="${work_dir}/xspec.properties"
    echo "saxon.custom.options=-config:\"${saxon_config}\" -t" > "${xspec_properties}"

    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/saxon-custom-options/test.xspec -lib "${SAXON_JAR}" -Dxspec.properties="${xspec_properties}" -Dtest.type=q
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 1 / pending: 0 / failed: 0 / total: 1" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]

    # Verify '-t'
    [[ "${output}" =~ "Memory used:" ]]
}


@test "invoking xspec for XSLT with SAXON_CUSTOM_OPTIONS" {
    # Test with a space in file name
    saxon_config="${work_dir}/saxon config.xml"
    cp saxon-custom-options/config.xml "${saxon_config}"

    export SAXON_CUSTOM_OPTIONS="\"-config:${saxon_config}\" -t"
    run ../bin/xspec.sh saxon-custom-options/test.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 1 / pending: 0 / failed: 0 / total: 1" ]]

    # Verify '-t'
    [[ "${output}" =~ "Memory used:" ]]
}


@test "invoking xspec for XQuery with SAXON_CUSTOM_OPTIONS" {
    # Test with a space in file name
    saxon_config="${work_dir}/saxon config.xml"
    cp saxon-custom-options/config.xml "${saxon_config}"

    export SAXON_CUSTOM_OPTIONS="\"-config:${saxon_config}\" -t"
    run ../bin/xspec.sh -q saxon-custom-options/test.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 1 / pending: 0 / failed: 0 / total: 1" ]]

    # Verify '-t'
    [[ "${output}" =~ "Memory used:" ]]
}


@test "Ant for XSLT with coverage creates report files" {
    if [ -z "${XSLT_SUPPORTS_COVERAGE}" ]; then
        skip "XSLT_SUPPORTS_COVERAGE is not defined"
    fi

    run ant -buildfile "${PWD}/../build.xml" -Dxspec.xml="${PWD}/../tutorial/coverage/demo.xspec" -lib "${SAXON_JAR}" -Dxspec.coverage.enabled=true
    echo "$output"
    [ "$status" -eq 0 ]
    [[ "${output}" =~ "passed: 1 / pending: 0 / failed: 0 / total: 1" ]]
    [[ "${output}" =~ "BUILD SUCCESSFUL" ]]

    # XML, HTML and coverage report file
    [ -f "../tutorial/coverage/xspec/demo-result.xml" ]
    [ -f "../tutorial/coverage/xspec/demo-result.html" ]
    [ -f "../tutorial/coverage/xspec/demo-coverage.html" ]
}


@test "Ant for XQuery with coverage fails" {
    run ant -buildfile "${PWD}/../build.xml" -Dxspec.xml="${PWD}/../tutorial/xquery-tutorial.xspec" -lib "${SAXON_JAR}" -Dtest.type=q -Dxspec.coverage.enabled=true
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "BUILD FAILED" ]]
    [[ "${output}" =~ "Coverage is supported only for XSLT" ]]
}


@test "Ant for Schematron with coverage fails" {
    run ant -buildfile "${PWD}/../build.xml" -Dxspec.xml="${PWD}/../tutorial/schematron/demo-01.xspec" -lib "${SAXON_JAR}" -Dtest.type=s -Dxspec.coverage.enabled=true
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "BUILD FAILED" ]]
    [[ "${output}" =~ "Coverage is supported only for XSLT" ]]
}


@test "Ant for XSLT with JUnit creates report files" {
    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/../tutorial/escape-for-regex.xspec -lib "${SAXON_JAR}" -Dxspec.junit.enabled=true
    echo "$output"
    [ "$status" -eq 1 ]
    [[ "${output}" =~ "passed: 5 / pending: 0 / failed: 1 / total: 6" ]]
    [[ "${output}" =~ "BUILD FAILED" ]]

    # XML report file
    [ -f "../tutorial/xspec/escape-for-regex-result.xml" ]

    # HTML report file
    [ -f "../tutorial/xspec/escape-for-regex-result.html" ]

    # JUnit report file
    [ -f "../tutorial/xspec/escape-for-regex-junit.xml" ]
}


@test "Import order #185" {
    # Make the line numbers predictable by providing an existing output dir
    export TEST_DIR="${work_dir}"

    run ../bin/xspec.sh xspec-185/import-1.xspec
    echo "$output"
    [ "$status" -eq 0 ]
    [ "${lines[4]}"  = "Scenario 1-1" ]
    [ "${lines[5]}"  = "Scenario 1-2" ]
    [ "${lines[6]}"  = "Scenario 1-3" ]
    [ "${lines[7]}"  = "Scenario 2a-1" ]
    [ "${lines[8]}"  = "Scenario 2a-2" ]
    [ "${lines[9]}"  = "Scenario 2b-1" ]
    [ "${lines[10]}" = "Scenario 2b-2" ]
    [ "${lines[11]}" = "Scenario 3" ]
    [ "${lines[12]}" = "Formatting Report..." ]
}


@test "Import order with Ant #185" {
    ant_log="${work_dir}/ant.log"

    run ant -buildfile ${PWD}/../build.xml -Dxspec.xml=${PWD}/xspec-185/import-1.xspec -lib "${SAXON_JAR}" -logfile "${ant_log}"
    echo "$output"
    [ "$status" -eq 0 ]

    run grep " Scenario " "${ant_log}"
    echo "$output"
    [ "${#lines[@]}" = "8" ]
    [ "${lines[0]}" = "     [java] Scenario 1-1" ]
    [ "${lines[1]}" = "     [java] Scenario 1-2" ]
    [ "${lines[2]}" = "     [java] Scenario 1-3" ]
    [ "${lines[3]}" = "     [java] Scenario 2a-1" ]
    [ "${lines[4]}" = "     [java] Scenario 2a-2" ]
    [ "${lines[5]}" = "     [java] Scenario 2b-1" ]
    [ "${lines[6]}" = "     [java] Scenario 2b-2" ]
    [ "${lines[7]}" = "     [java] Scenario 3" ]
}


@test "Ambiguous x:expect generates warning" {
    # Provide TEST_DIR with an existing directory to make the output lines predictable
    export TEST_DIR="${work_dir}"
    run ../bin/xspec.sh end-to-end/cases/xspec-ambiguous-expect.xspec
    echo "$output"
    [[ "${lines[9]}"  =~ "WARNING: x:expect has boolean @test" ]]
    [[ "${lines[14]}" =~ "WARNING: x:expect has boolean @test" ]]
    [[ "${lines[21]}" =~ "WARNING: x:expect has boolean @test" ]]
    [  "${lines[30]}" =  "Formatting Report..." ]
}


