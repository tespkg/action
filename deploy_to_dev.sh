echo "---------- run deploy_to_dev --------------"

echo ${who-to-greet}
echo ${inputENV}

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
echo "latest GITLAB_IMAGE_TAG is sha-${GITHUB_SHA:0:7}"            
yq w -i values.yaml "common*.image.tag" sha-${GITHUB_SHA:0:7}
yq r --printMode pv values.yaml "common*.image.tag"

echo "push the latest SHA: ${GITHUB_SHA:0:7} to manifest repo"
git config user.name ${GITHUB_ACTOR}
git config user.email ${GITHUB_ACTOR}@github.com
git diff
git add ./
git commit -m "${GITHUB_REPOSITORY}_${GITHUB_JOB}_${GITHUB_SHA:0:7}_details:${CI_COMMIT_MESSAGE}"
git push
echo -e "======================= \n\n you can check your application status with 'user/passwd:readonly/Te****g' at \n\n \033[31m https://g-argocd.fluxble.com/applications/${APP_PROJECT_NAME}-${APP_CHART_NAME}\033[0m \n\n======================="