echo "---------- run deploy_to_dev --------------"

echo "APP_PROJECT_NAME2 is ${APP_PROJECT_NAME2}"
echo "APP_PROJECT_NAME3 is ${APP_PROJECT_NAME3}"
echo "APP_PROJECT_NAME4 is ${APP_PROJECT_NAME4}"
echo "APP_PROJECT_NAME5 is ${APP_PROJECT_NAME5}"
echo "GITLAB_REGISTRY is ${GITLAB_REGISTRY}"
echo "GITHUB_REPOSITORY is ${GITHUB_REPOSITORY}"
echo "COMMON2 is ${COMMON2}"
echo "COMMON3 is ${COMMON3}"
echo "COMMON4 is ${COMMON4}"

cd helm/${APP_PROJECT_NAME}/${APP_CHART_NAME}
EXPECT_CHART=`echo ${GITHUB_REPOSITORY} | awk -F "/" '{print $2}'`
TARGET_CHART=`yq r Chart.yaml name`
echo "verify the EXPECT_CHART:$EXPECT_CHART and TARGET_CHART:$TARGET_CHART"
if [ "$EXPECT_CHART" != "$TARGET_CHART" ];then
echo "TARGET_CHART $TARGET_CHART not same as EXPECT_CHART $EXPECT_CHART, please check"
exit 1
fi

echo "list current common*.image.repository"
yq r --printMode pv values.yaml "common*.image.repository"
echo "latest GITLAB_IMAGE_NAME is ${GITLAB_REGISTRY}/${GITHUB_REPOSITORY}"
yq w -i values.yaml "common*.image.repository" ${GITLAB_REGISTRY}/${GITHUB_REPOSITORY}
yq r --printMode pv values.yaml "common*.image.repository"
            
echo "list current common*.image.tag"
yq r --printMode pv values.yaml "common*.image.tag"
echo "latest GITLAB_IMAGE_TAG is ${GITHUB_SHA:0:8}"            
yq w -i values.yaml "common*.image.tag" ${GITHUB_SHA:0:8}
yq r --printMode pv values.yaml "common*.image.tag"

if [ "$COMMON2" != "false" ];then
echo "list common2.image tag"
yq r --printMode pv values.yaml "common*.image.tag"
fi



echo "push the latest SHA: ${GITHUB_SHA:0:8} to manifest repo"
git config user.name ${GITHUB_ACTOR}
git config user.email ${GITHUB_ACTOR}@github.com
git diff
git add ./
git commit -m "${GITHUB_REPOSITORY}_${GITHUB_JOB}_${GITHUB_SHA:0:8}_details:${CI_COMMIT_MESSAGE}"
git push
echo -e "======================= \n\n you can check your application status with 'user/passwd:readonly/Te****g' at \n\n \033[31m https://g-argocd.fluxble.com/applications/${APP_PROJECT_NAME}-${APP_CHART_NAME}\033[0m \n\n======================="